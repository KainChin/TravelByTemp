using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace VietAITravel.Api.Services;

public class OllamaOptions
{
    public string BaseUrl { get; set; } = "http://localhost:11434";
    public string ChatModel { get; set; } = "llama3.1:8b";
    public string EmbeddingModel { get; set; } = "nomic-embed-text";
}

public class OllamaService(HttpClient http, OllamaOptions options, ILogger<OllamaService> logger)
{
    public string ChatModel => options.ChatModel;
    public string EmbeddingModel => options.EmbeddingModel;

    public async Task<float[]> GetEmbeddingAsync(string text, CancellationToken ct = default)
    {
        var payload = new { model = options.EmbeddingModel, prompt = text };
        try
        {
            var response = await http.PostAsJsonAsync("/api/embeddings", payload, ct);
            response.EnsureSuccessStatusCode();
            var doc = await response.Content.ReadFromJsonAsync<EmbeddingResponse>(cancellationToken: ct);
            return doc?.Embedding ?? Array.Empty<float>();
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Ollama embedding failed, using fallback hash vector");
            return FallbackEmbedding(text, 768);
        }
    }

    public async Task<string> ChatAsync(string prompt, CancellationToken ct = default)
    {
        var payload = new
        {
            model = options.ChatModel,
            messages = new[] { new { role = "user", content = prompt } },
            stream = false,
            format = "json"
        };

        try
        {
            var response = await http.PostAsJsonAsync("/api/chat", payload, ct);
            response.EnsureSuccessStatusCode();
            var doc = await response.Content.ReadFromJsonAsync<ChatResponse>(cancellationToken: ct);
            return doc?.Message?.Content ?? "{}";
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Ollama chat failed, using rule-based JSON");
            return string.Empty;
        }
    }

    private static float[] FallbackEmbedding(string text, int dimensions)
    {
        var vec = new float[dimensions];
        var hash = text.GetHashCode();
        for (var i = 0; i < dimensions; i++)
            vec[i] = (float)Math.Sin(hash + i * 0.01) * 0.5f;
        return vec;
    }

    private sealed class EmbeddingResponse
    {
        [JsonPropertyName("embedding")]
        public float[] Embedding { get; set; } = Array.Empty<float>();
    }

    private sealed class ChatResponse
    {
        [JsonPropertyName("message")]
        public ChatMessage? Message { get; set; }
    }

    private sealed class ChatMessage
    {
        [JsonPropertyName("content")]
        public string Content { get; set; } = "";
    }
}
