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
using VietAITravel.Api.Services.TravelCompanion;

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
builder.Services.AddHttpClient("ollama-chat", c => c.Timeout = TimeSpan.FromSeconds(45));
builder.Services.AddHttpClient<WeatherService>();
builder.Services.AddScoped<VectorSearchService>();
builder.Services.AddScoped<AiRecommendationService>();

var lmStudioOpts = new LmStudioOptions
{
    BaseUrl = builder.Configuration["LMStudio:BaseUrl"] ?? "http://localhost:1234/v1",
    ChatModel = builder.Configuration["LMStudio:ChatModel"] ?? "local-model",
    ApiKey = builder.Configuration["LMStudio:ApiKey"] ?? "lm-studio"
};
builder.Services.AddSingleton(lmStudioOpts);
builder.Services.AddHttpClient("lm-studio", c => c.Timeout = TimeSpan.FromMinutes(3));

var openTripMapOpts = new OpenTripMapOptions
{
    ApiKey = builder.Configuration["OpenTripMap:ApiKey"] ?? "",
    BaseUrl = builder.Configuration["OpenTripMap:BaseUrl"] ?? "https://api.opentripmap.com"
};
builder.Services.AddSingleton(openTripMapOpts);
builder.Services.AddHttpClient<DestinationDiscoveryService>();
builder.Services.AddScoped<SemanticKernelTravelOrchestrator>();
builder.Services.AddScoped<TravelMemoryService>();
builder.Services.AddScoped<TravelPlannerService>();

var openAiOpts = new OpenAiOptions
{
    ApiKey = builder.Configuration["OpenAI:ApiKey"] ?? "",
    BaseUrl = builder.Configuration["OpenAI:BaseUrl"] ?? "https://api.openai.com/v1",
    VisionModel = builder.Configuration["OpenAI:VisionModel"] ?? "gpt-4o-mini"
};
builder.Services.AddSingleton(openAiOpts);
builder.Services.AddHttpClient("openai", c => c.Timeout = TimeSpan.FromSeconds(90));

var geminiOpts = new GeminiOptions
{
    ApiKey = builder.Configuration["Gemini:ApiKey"] ?? "",
    BaseUrl = builder.Configuration["Gemini:BaseUrl"] ?? "https://generativelanguage.googleapis.com",
    VisionModel = builder.Configuration["Gemini:VisionModel"] ?? "gemini-2.0-flash"
};
builder.Services.AddSingleton(geminiOpts);
builder.Services.AddHttpClient("gemini", c => c.Timeout = TimeSpan.FromSeconds(90));

var groqOpts = new GroqOptions
{
    ApiKey = builder.Configuration["Groq:ApiKey"] ?? "",
    BaseUrl = builder.Configuration["Groq:BaseUrl"] ?? "https://api.groq.com/openai/v1",
    VisionModel = builder.Configuration["Groq:VisionModel"] ?? "meta-llama/llama-4-scout-17b-16e-instruct"
};
builder.Services.AddSingleton(groqOpts);
builder.Services.AddHttpClient("groq", c => c.Timeout = TimeSpan.FromSeconds(90));

var googleMapsOpts = new GoogleMapsOptions
{
    ApiKey = builder.Configuration["GoogleMaps:ApiKey"] ?? "",
    BaseUrl = builder.Configuration["GoogleMaps:BaseUrl"] ?? "https://maps.googleapis.com"
};
builder.Services.AddSingleton(googleMapsOpts);
builder.Services.AddScoped<RouteAnalysisService>();

builder.Services.AddScoped<ContentActivityService>();
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

var uploadsDir = Path.Combine(app.Environment.ContentRootPath, "wwwroot", "uploads");
Directory.CreateDirectory(uploadsDir);
app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = new Microsoft.Extensions.FileProviders.PhysicalFileProvider(uploadsDir),
    RequestPath = "/uploads"
});

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
    CancellationToken ct) =>
{
    try
    {
        var result = await service.GenerateItineraryAsync(request, ct);
        // KHÔNG tự lưu vào database khi generate — để user xem lịch trình trước
        // rồi chủ động bấm "Lưu chuyến đi". Việc lưu sẽ được thực hiện qua
        // endpoint `POST /api/trip/itineraries` ở phía frontend.
        return Results.Ok(result with { ItineraryId = (Guid?)null });
    }
    catch (TravelAiException ex)
    {
        return Results.Problem(ex.Message, statusCode: ex.StatusCode);
    }
});

app.MapPost("/api/trip/analyze-route", async (
    AnalyzeRouteRequest request,
    RouteAnalysisService service,
    AppDbContext db,
    HttpContext httpContext,
    CancellationToken ct) =>
{
    try
    {
        var result = await service.AnalyzeAsync(request, ct);
        var userIdValue = httpContext.User.FindFirstValue(ClaimTypes.NameIdentifier);
        Guid? userId = Guid.TryParse(userIdValue, out var parsedUserId) ? parsedUserId : null;
        var routeId = Guid.NewGuid();

        var route = new TripRoute
        {
            Id = routeId,
            UserId = userId,
            DepartureName = result.Departure.Name,
            DepartureLatitude = result.Departure.Latitude,
            DepartureLongitude = result.Departure.Longitude,
            TotalDistanceKm = result.TotalDistanceKm,
            OptimizedHours = result.OptimizedHours,
            PeopleCount = request.PeopleCount,
            BudgetPerPerson = request.BudgetPerPerson,
            HasFlightLeg = result.HasFlightLeg,
            CreatedAt = DateTime.UtcNow,
            Legs = result.Legs.Select(leg => new TripRouteLeg
            {
                Id = Guid.NewGuid(),
                TripRouteId = routeId,
                LegOrder = leg.Order,
                FromName = leg.FromName,
                ToName = leg.To.Name,
                ToRegion = leg.To.Region,
                ToLatitude = leg.To.Latitude,
                ToLongitude = leg.To.Longitude,
                DistanceKm = leg.DistanceKm,
                DurationHours = leg.DurationHours,
                RecommendedMode = leg.RecommendedMode,
                Reason = leg.Reason,
                IsGoogleEstimate = leg.IsGoogleEstimate
            }).ToList()
        };

        db.TripRoutes.Add(route);
        await db.SaveChangesAsync(ct);

        return Results.Ok(result with { RouteId = routeId });
    }
    catch (TravelAiException ex)
    {
        return Results.Problem(ex.Message, statusCode: ex.StatusCode);
    }
});

app.MapGet("/api/trip/routes", async (
    AppDbContext db,
    HttpContext httpContext,
    CancellationToken ct) =>
{
    var userIdValue = httpContext.User.FindFirstValue(ClaimTypes.NameIdentifier);
    Guid? userId = Guid.TryParse(userIdValue, out var parsedUserId) ? parsedUserId : null;

    var query = db.TripRoutes
        .AsNoTracking()
        .Include(x => x.Legs)
        .AsQueryable();

    query = userId.HasValue
        ? query.Where(x => x.UserId == userId)
        : query.Where(x => x.UserId == null);

    var routes = await query
        .OrderByDescending(x => x.CreatedAt)
        .Take(20)
        .Select(x => new
        {
            x.Id,
            x.DepartureName,
            x.DepartureLatitude,
            x.DepartureLongitude,
            x.TotalDistanceKm,
            x.OptimizedHours,
            x.PeopleCount,
            x.BudgetPerPerson,
            x.HasFlightLeg,
            x.CreatedAt,
            Legs = x.Legs
                .OrderBy(leg => leg.LegOrder)
                .Select(leg => new
                {
                    leg.LegOrder,
                    leg.FromName,
                    leg.ToName,
                    leg.ToRegion,
                    leg.ToLatitude,
                    leg.ToLongitude,
                    leg.DistanceKm,
                    leg.DurationHours,
                    leg.RecommendedMode,
                    leg.Reason,
                    leg.IsGoogleEstimate
                })
        })
        .ToListAsync(ct);

    return Results.Ok(routes);
});

app.MapGet("/api/trip/itineraries", async (
    AppDbContext db,
    HttpContext httpContext,
    CancellationToken ct) =>
{
    var userIdValue = httpContext.User.FindFirstValue(ClaimTypes.NameIdentifier);
    Guid? userId = Guid.TryParse(userIdValue, out var parsedUserId) ? parsedUserId : null;

    var query = db.AiItineraries.AsNoTracking();
    query = userId.HasValue
        ? query.Where(x => x.UserId == userId)
        : query.Where(x => x.UserId == null);

    var rows = await query
        .OrderByDescending(x => x.CreatedAt)
        .Take(20)
        .ToListAsync(ct);

    var items = rows
        .Select(x => new AiItineraryHistoryItem(
            x.Id,
            x.Title,
            x.AiModel,
            x.CreatedAt,
            TryDeserializeJson(x.ItineraryJson)))
        .ToList();

    return Results.Ok(new AiItineraryHistoryResponse("Da lay lich su lich trinh.", items));
});

app.MapPost("/api/trip/itineraries", async (
    SaveItineraryRequest request,
    AppDbContext db,
    OllamaOptions ollamaOptions,
    HttpContext httpContext,
    CancellationToken ct) =>
{
    var userIdValue = httpContext.User.FindFirstValue(ClaimTypes.NameIdentifier);
    Guid? userId = Guid.TryParse(userIdValue, out var parsedUserId) ? parsedUserId : null;
    var itineraryJson = JsonSerializer.Serialize(request.Itinerary);
    var title = string.IsNullOrWhiteSpace(request.Title)
        ? TryReadTitle(itineraryJson)
        : request.Title.Trim();

    AiItinerary? row = null;
    if (request.ItineraryId.HasValue)
    {
        row = await db.AiItineraries.FirstOrDefaultAsync(x => x.Id == request.ItineraryId.Value, ct);
    }

    if (row is null)
    {
        row = new AiItinerary
        {
            Id = request.ItineraryId ?? Guid.NewGuid(),
            UserId = userId,
            CreatedAt = DateTime.UtcNow,
            RequestJson = "{}",
            AiModel = ollamaOptions.ChatModel
        };
        db.AiItineraries.Add(row);
    }

    row.UserId = userId;
    row.Title = title;
    row.ItineraryJson = itineraryJson;
    row.AiModel ??= ollamaOptions.ChatModel;

    await db.SaveChangesAsync(ct);

    return Results.Ok(new AiItineraryHistoryItem(
        row.Id,
        row.Title,
        row.AiModel,
        row.CreatedAt,
        TryDeserializeJson(row.ItineraryJson)));
});

app.MapDelete("/api/trip/itineraries/{id:guid}", async (
    Guid id,
    AppDbContext db,
    HttpContext httpContext,
    CancellationToken ct) =>
{
    var userIdValue = httpContext.User.FindFirstValue(ClaimTypes.NameIdentifier);
    Guid? userId = Guid.TryParse(userIdValue, out var parsedUserId) ? parsedUserId : null;

    var row = await db.AiItineraries.FirstOrDefaultAsync(x => x.Id == id, ct);
    if (row is null) return Results.NotFound();

    if (row.UserId != userId) return Results.Forbid();

    db.AiItineraries.Remove(row);
    await db.SaveChangesAsync(ct);
    return Results.NoContent();
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

static object? TryDeserializeJson(string json)
{
    try
    {
        return JsonSerializer.Deserialize<object>(json);
    }
    catch
    {
        return null;
    }
}

public partial class Program;
