using VietAITravel.Api.Services;
using Xunit;

namespace VietAITravel.Tests;

public class HtmlSanitizerTests
{
    [Fact]
    public void Sanitize_RemovesScriptTags()
    {
        var input = "<p>Hello</p><script>alert('x')</script>";
        var result = HtmlSanitizer.Sanitize(input);
        Assert.DoesNotContain("<script", result, StringComparison.OrdinalIgnoreCase);
        Assert.Contains("Hello", result);
    }

    [Fact]
    public void Sanitize_RemovesEventHandlers()
    {
        var input = """<img src="x" onerror="alert(1)" alt="test" />""";
        var result = HtmlSanitizer.Sanitize(input);
        Assert.DoesNotContain("onerror", result, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void Sanitize_RemovesJavascriptUrls()
    {
        var input = """<a href="javascript:alert(1)">click</a>""";
        var result = HtmlSanitizer.Sanitize(input);
        Assert.DoesNotContain("javascript:", result, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void Sanitize_NullOrEmpty_ReturnsEmpty()
    {
        Assert.Equal(string.Empty, HtmlSanitizer.Sanitize(null));
        Assert.Equal(string.Empty, HtmlSanitizer.Sanitize("   "));
    }
}
