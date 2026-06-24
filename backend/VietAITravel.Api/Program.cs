using System.Security.Claims;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.EntityFrameworkCore;
using VietAITravel.Api.DTOs;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using Pgvector.EntityFrameworkCore;
using VietAITravel.Api.Data;
using VietAITravel.Api.Entities;
using VietAITravel.Api.Middleware;
using VietAITravel.Api.Services;

var builder = WebApplication.CreateBuilder(args);

builder.Logging.ClearProviders();
builder.Logging.AddConsole();
builder.Logging.AddDebug();

builder.Services.AddDataProtection()
    .PersistKeysToFileSystem(new DirectoryInfo(Path.Combine(Path.GetTempPath(), "VietAITravel-DataProtectionKeys")));

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "VietAI Travel API", Version = "v1" });
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "JWT Bearer token",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.Http,
        Scheme = "bearer"
    });
    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer" }
            },
            Array.Empty<string>()
        }
    });
});

builder.Services.AddCors(o => o.AddDefaultPolicy(p =>
    p.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod()));

var conn = builder.Configuration.GetConnectionString("Postgres")!;
builder.Services.AddDbContext<AppDbContext>(opt =>
{
    opt.UseNpgsql(conn, npg => npg.UseVector());
});

var jwt = new JwtOptions
{
    SecretKey = builder.Configuration["Jwt:SecretKey"]!,
    Issuer = builder.Configuration["Jwt:Issuer"]!,
    Audience = builder.Configuration["Jwt:Audience"]!,
    ExpiryMinutes = int.Parse(builder.Configuration["Jwt:ExpiryMinutes"] ?? "60")
};
builder.Services.AddSingleton(jwt);
builder.Services.AddScoped<AuthService>();

var ollamaOpts = new OllamaOptions
{
    BaseUrl = builder.Configuration["Ollama:BaseUrl"]!,
    ChatModel = builder.Configuration["Ollama:ChatModel"]!,
    EmbeddingModel = builder.Configuration["Ollama:EmbeddingModel"]!
};
builder.Services.AddSingleton(ollamaOpts);
builder.Services.AddHttpClient<OllamaService>(c => c.BaseAddress = new Uri(ollamaOpts.BaseUrl));
builder.Services.AddHttpClient("ollama-chat", c => c.Timeout = TimeSpan.FromMinutes(5));
builder.Services.AddHttpClient<WeatherService>();
builder.Services.AddScoped<VectorSearchService>();
builder.Services.AddScoped<AiRecommendationService>();

var openAiOpts = new OpenAiOptions
{
    ApiKey = builder.Configuration["OpenAI:ApiKey"] ?? "",
    BaseUrl = builder.Configuration["OpenAI:BaseUrl"] ?? "https://api.openai.com/v1",
    VisionModel = builder.Configuration["OpenAI:VisionModel"] ?? "gpt-4o-mini"
};
builder.Services.AddSingleton(openAiOpts);
builder.Services.AddHttpClient("openai", c => c.Timeout = TimeSpan.FromSeconds(90));
builder.Services.AddScoped<TravelChatService>();

var mongoOpts = new MongoOptions
{
    ConnectionString = builder.Configuration["MongoDb:ConnectionString"]!,
    DatabaseName = builder.Configuration["MongoDb:DatabaseName"]!
};
builder.Services.AddSingleton(mongoOpts);
builder.Services.AddSingleton<MongoLogService>();

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(opt =>
    {
        opt.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = jwt.Issuer,
            ValidAudience = jwt.Audience,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwt.SecretKey))
        };
    });
builder.Services.AddAuthorization();
builder.Services.AddSingleton<EmbeddingSeedService>();
builder.Services.AddHostedService(sp => sp.GetRequiredService<EmbeddingSeedService>());

var app = builder.Build();

app.UseSwagger();
app.UseSwaggerUI();
app.UseMiddleware<ExceptionHandlingMiddleware>();
app.UseCors();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

app.MapPost("/api/chat", async (
    ChatRequest request,
    TravelChatService service,
    CancellationToken ct) =>
{
    try
    {
        return Results.Ok(await service.ChatAsync(request, ct));
    }
    catch (TravelAiException ex)
    {
        return Results.Problem(ex.Message, statusCode: ex.StatusCode);
    }
});

app.MapPost("/api/chat-ai", async (
    HttpRequest request,
    TravelChatService service,
    CancellationToken ct) =>
{
    try
    {
        if (!request.HasFormContentType)
            return Results.Problem("Request must be multipart/form-data.", statusCode: StatusCodes.Status400BadRequest);

        var form = await request.ReadFormAsync(ct);
        var message = form["message"].ToString();
        var image = form.Files.GetFile("image");
        if (image is null)
            return Results.Problem("Image file field 'image' is required.", statusCode: StatusCodes.Status400BadRequest);

        return Results.Ok(await service.ChatWithImageAsync(message, image, ct));
    }
    catch (TravelAiException ex)
    {
        return Results.Problem(ex.Message, statusCode: ex.StatusCode);
    }
});

app.MapPost("/api/trip/generate-itinerary", async (
    GenerateItineraryRequest request,
    TravelChatService service,
    AppDbContext db,
    OllamaOptions ollamaOptions,
    HttpContext httpContext,
    CancellationToken ct) =>
{
    try
    {
        var result = await service.GenerateItineraryAsync(request, ct);
        var itineraryId = Guid.NewGuid();
        var userIdValue = httpContext.User.FindFirstValue(ClaimTypes.NameIdentifier);
        Guid? userId = Guid.TryParse(userIdValue, out var parsedUserId) ? parsedUserId : null;

        var itineraryJson = JsonSerializer.Serialize(result.Itinerary);
        var title = TryReadTitle(itineraryJson);
        db.AiItineraries.Add(new AiItinerary
        {
            Id = itineraryId,
            UserId = userId,
            Title = title,
            RequestJson = JsonSerializer.Serialize(request),
            ItineraryJson = itineraryJson,
            AiModel = ollamaOptions.ChatModel,
            CreatedAt = DateTime.UtcNow
        });
        await db.SaveChangesAsync(ct);

        return Results.Ok(result with { ItineraryId = itineraryId });
    }
    catch (TravelAiException ex)
    {
        return Results.Problem(ex.Message, statusCode: ex.StatusCode);
    }
});

await DbSeeder.SeedAsync(app.Services, builder.Configuration);

app.Run();

static string? TryReadTitle(string itineraryJson)
{
    try
    {
        using var doc = JsonDocument.Parse(itineraryJson);
        return doc.RootElement.TryGetProperty("title", out var title)
            ? title.GetString()
            : null;
    }
    catch
    {
        return null;
    }
}

public partial class Program;
