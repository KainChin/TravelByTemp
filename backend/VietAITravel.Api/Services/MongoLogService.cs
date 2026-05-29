using MongoDB.Driver;
using VietAITravel.Api.Mongo;

namespace VietAITravel.Api.Services;

public class MongoOptions
{
    public string ConnectionString { get; set; } = "mongodb://localhost:27017";
    public string DatabaseName { get; set; } = "vietai_ai_logs";
}

public class MongoLogService
{
    private readonly IMongoCollection<AiRecommendationLog> _aiLogs;
    private readonly IMongoCollection<WeatherSnapshot> _weather;
    private readonly IMongoCollection<UserInteractionLog> _interactions;

    public MongoLogService(MongoOptions options)
    {
        var client = new MongoClient(options.ConnectionString);
        var db = client.GetDatabase(options.DatabaseName);
        _aiLogs = db.GetCollection<AiRecommendationLog>("ai_recommendation_logs");
        _weather = db.GetCollection<WeatherSnapshot>("weather_snapshots");
        _interactions = db.GetCollection<UserInteractionLog>("user_interaction_logs");
    }

    public async Task<string> SaveAiLogAsync(AiRecommendationLog log, CancellationToken ct = default)
    {
        await _aiLogs.InsertOneAsync(log, cancellationToken: ct);
        return log.Id!;
    }

    public async Task<string> SaveWeatherSnapshotAsync(WeatherSnapshot snapshot, CancellationToken ct = default)
    {
        await _weather.InsertOneAsync(snapshot, cancellationToken: ct);
        return snapshot.Id!;
    }

    public async Task LogInteractionAsync(UserInteractionLog log, CancellationToken ct = default) =>
        await _interactions.InsertOneAsync(log, cancellationToken: ct);
}
