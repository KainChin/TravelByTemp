namespace VietAITravel.Api.Services;

public static class EmbeddingVector
{
    public const int Dimensions = 768;

    public static float[] NormalizeDimension(float[] embedding)
    {
        if (embedding.Length == Dimensions) return embedding;
        if (embedding.Length == 0) return new float[Dimensions];

        var result = new float[Dimensions];
        for (var i = 0; i < Dimensions; i++)
            result[i] = embedding[i % embedding.Length];

        return result;
    }
}
