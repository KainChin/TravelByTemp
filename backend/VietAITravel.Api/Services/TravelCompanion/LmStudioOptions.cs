namespace VietAITravel.Api.Services.TravelCompanion;

public sealed class LmStudioOptions
{
    public string BaseUrl { get; set; } = "http://localhost:1234/v1";
    public string ChatModel { get; set; } = "local-model";
    public string ApiKey { get; set; } = "lm-studio";
}
