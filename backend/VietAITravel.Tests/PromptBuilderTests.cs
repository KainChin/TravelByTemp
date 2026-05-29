using VietAITravel.Api.DTOs;
using VietAITravel.Api.Entities;
using VietAITravel.Api.Services;
using Xunit;

namespace VietAITravel.Tests;

public class PromptBuilderTests
{
    [Fact]
    public void AiRecommendRequest_HasRequiredFields()
    {
        var req = new AiRecommendRequest(10.77, 106.70, "TP.HCM", 2_000_000, 3, "thiên nhiên, mát mẻ");
        Assert.Equal(3, req.TotalDays);
        Assert.Equal(2_000_000, req.BudgetInput);
    }

    [Fact]
    public void VectorSearchResult_StoresSimilarity()
    {
        var dest = new Destination { Id = Guid.NewGuid(), Name = "Đà Lạt" };
        var result = new VectorSearchResult(dest, 0.92);
        Assert.Equal(0.92, result.Similarity);
    }
}
