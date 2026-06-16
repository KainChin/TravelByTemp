using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using Pgvector.EntityFrameworkCore;
using VietAITravel.Api.Data;
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
builder.Services.AddHttpClient<WeatherService>();
builder.Services.AddScoped<VectorSearchService>();
builder.Services.AddScoped<AiRecommendationService>();

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

await DbSeeder.SeedAsync(app.Services, builder.Configuration);

app.Run();

public partial class Program;
