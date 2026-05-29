using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace VietAITravel.Api.Mongo;

public class AiRecommendationLog
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string? Id { get; set; }

    public string UserId { get; set; } = null!;
    public string? ScheduleId { get; set; }
    public string AiModelUsed { get; set; } = null!;
    public string EmbeddingModelUsed { get; set; } = null!;
    public string PromptText { get; set; } = null!;
    public string RawResponseText { get; set; } = null!;
    public BsonDocument? ParsedResponse { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

public class WeatherSnapshot
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string? Id { get; set; }

    public string UserId { get; set; } = null!;
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public string LocationName { get; set; } = null!;
    public double Temperature { get; set; }
    public string WeatherDescription { get; set; } = null!;
    public double? Humidity { get; set; }
    public double? WindSpeed { get; set; }
    public string Source { get; set; } = "OpenMeteo";
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

public class UserInteractionLog
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string? Id { get; set; }

    public string UserId { get; set; } = null!;
    public string EventType { get; set; } = null!;
    public string? DestinationId { get; set; }
    public BsonDocument? Metadata { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
