using Microsoft.EntityFrameworkCore;
using Pgvector;
using VietAITravel.Api.Data;

namespace VietAITravel.Api.Services;

/// <summary>
/// Tạo embedding cho mọi địa điểm active khi khởi động (và khi thiếu embedding).
/// </summary>
public class EmbeddingSeedService(
    IServiceProvider services,
    IConfiguration config,
    ILogger<EmbeddingSeedService> logger) : IHostedService
{
    public Task StartAsync(CancellationToken cancellationToken)
    {
        if (!bool.TryParse(config["Seed:RunOnStartup"], out var run) || !run)
            return Task.CompletedTask;

        _ = Task.Run(async () =>
        {
            await Task.Delay(TimeSpan.FromSeconds(8), cancellationToken);
            await EmbedAllMissingAsync(cancellationToken);
        }, cancellationToken);

        return Task.CompletedTask;
    }

    public Task StopAsync(CancellationToken cancellationToken) => Task.CompletedTask;

    public async Task<int> EmbedAllMissingAsync(CancellationToken ct = default)
    {
        using var scope = services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var ollama = scope.ServiceProvider.GetRequiredService<OllamaService>();

        if (!await db.Database.CanConnectAsync(ct))
            return 0;

        var destinations = await db.Destinations
            .Where(d => d.IsActive && d.Embedding == null)
            .ToListAsync(ct);

        var count = 0;
        foreach (var dest in destinations)
        {
            try
            {
                var text = dest.EmbeddingText
                    ?? $"{dest.Name} {dest.Province} {dest.Region} {dest.Category} {dest.Description} {dest.TravelStyle}";
                dest.EmbeddingText = text;
                var emb = await ollama.GetEmbeddingAsync(text, ct);
                dest.Embedding = new Vector(EmbeddingVector.NormalizeDimension(emb));
                dest.UpdatedAt = DateTime.UtcNow;
                count++;
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "Embedding failed for {Name}", dest.Name);
            }
        }

        if (count > 0)
        {
            await db.SaveChangesAsync(ct);
            logger.LogInformation("Generated embeddings for {Count} destinations", count);
        }

        return count;
    }
}
