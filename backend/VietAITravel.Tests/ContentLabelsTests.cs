using VietAITravel.Api.Services;
using Xunit;

namespace VietAITravel.Tests;

public class ContentLabelsTests
{
    [Theory]
    [InlineData("destination", "Địa điểm")]
    [InlineData("experience", "Kinh nghiệm")]
    [InlineData("news", "Tin tức")]
    [InlineData("other", "other")]
    public void CategoryLabel_ReturnsExpected(string input, string expected) =>
        Assert.Equal(expected, ContentLabels.CategoryLabel(input));

    [Theory]
    [InlineData("published", "Đã xuất bản")]
    [InlineData("pending", "Chờ duyệt")]
    [InlineData("draft", "Bản nháp")]
    [InlineData("unknown", "unknown")]
    public void StatusLabel_ReturnsExpected(string input, string expected) =>
        Assert.Equal(expected, ContentLabels.StatusLabel(input));
}
