using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using VietAITravel.Api.Data;
using VietAITravel.Api.DTOs;
using VietAITravel.Api.Entities;

namespace VietAITravel.Api.Services.TravelCompanion;

public sealed class TravelMemoryService(AppDbContext db)
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    public async Task<TravelMemoryDto> GetAsync(Guid userId, CancellationToken ct)
    {
        var memory = await db.UserTravelMemories.AsNoTracking()
            .FirstOrDefaultAsync(x => x.UserId == userId, ct);

        if (memory == null)
            return new TravelMemoryDto([], "", 0, 0, "");

        return new TravelMemoryDto(
            DeserializeStyles(memory.PreferredStylesJson),
            memory.PreferredTransport,
            memory.AverageBudget,
            memory.TripCount,
            memory.Notes);
    }

    public async Task UpdateFromTripAsync(
        Guid userId,
        IReadOnlyList<string> preferences,
        string transport,
        decimal budget,
        string? notes,
        CancellationToken ct)
    {
        var memory = await db.UserTravelMemories
            .FirstOrDefaultAsync(x => x.UserId == userId, ct);

        if (memory == null)
        {
            memory = new UserTravelMemory
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                CreatedAt = DateTime.UtcNow
            };
            db.UserTravelMemories.Add(memory);
        }

        var existing = DeserializeStyles(memory.PreferredStylesJson);
        var merged = existing
            .Concat(preferences)
            .Where(x => !string.IsNullOrWhiteSpace(x))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .Take(12)
            .ToList();

        memory.PreferredStylesJson = JsonSerializer.Serialize(merged, JsonOptions);
        memory.PreferredTransport = string.IsNullOrWhiteSpace(transport)
            ? memory.PreferredTransport
            : transport;
        memory.AverageBudget = memory.TripCount <= 0
            ? budget
            : ((memory.AverageBudget * memory.TripCount) + budget) / (memory.TripCount + 1);
        memory.TripCount += 1;
        memory.Notes = string.IsNullOrWhiteSpace(notes) ? memory.Notes : notes;
        memory.UpdatedAt = DateTime.UtcNow;

        await db.SaveChangesAsync(ct);
    }

    private static IReadOnlyList<string> DeserializeStyles(string json)
    {
        try
        {
            return JsonSerializer.Deserialize<List<string>>(json, JsonOptions) ?? [];
        }
        catch
        {
            return [];
        }
    }
}
