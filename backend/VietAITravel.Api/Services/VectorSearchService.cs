using Microsoft.EntityFrameworkCore;
using Pgvector;
using VietAITravel.Api.Data;
using VietAITravel.Api.Entities;

namespace VietAITravel.Api.Services;

public record VectorSearchResult(Destination Destination, double Similarity);

public class VectorSearchService(AppDbContext db)
{
    public async Task<IReadOnlyList<VectorSearchResult>> SearchAsync(
        float[] queryEmbedding, int topK, decimal? maxBudget, CancellationToken ct = default)
    {
        var query = db.Destinations.AsNoTracking().Where(d => d.IsActive);
        if (maxBudget.HasValue)
            query = query.Where(d => d.EstimatedCost <= maxBudget.Value);

        var destinations = await query.ToListAsync(ct);
        if (destinations.Count == 0)
            return Array.Empty<VectorSearchResult>();

        var withEmbedding = destinations.Where(d => d.Embedding != null).ToList();
        if (withEmbedding.Count == 0 || queryEmbedding.Length == 0)
        {
            return destinations.Take(topK)
                .Select(d => new VectorSearchResult(d, 0.5))
                .ToList();
        }

        var queryVector = new Vector(queryEmbedding);
        return withEmbedding
            .Select(d => new VectorSearchResult(d, CosineSimilarity(queryVector, d.Embedding!)))
            .OrderByDescending(x => x.Similarity)
            .Take(topK)
            .ToList();
    }

    private static double CosineSimilarity(Vector a, Vector b)
    {
        var av = a.ToArray();
        var bv = b.ToArray();
        if (av.Length != bv.Length || av.Length == 0) return 0;

        double dot = 0, na = 0, nb = 0;
        for (var i = 0; i < av.Length; i++)
        {
            dot += av[i] * bv[i];
            na += av[i] * av[i];
            nb += bv[i] * bv[i];
        }

        if (na == 0 || nb == 0) return 0;
        return dot / (Math.Sqrt(na) * Math.Sqrt(nb));
    }
}
