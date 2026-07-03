using System.Text.RegularExpressions;

namespace VietAITravel.Api.Services;

public static class HtmlSanitizer
{
    private static readonly Regex ScriptTag = new(@"<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>", RegexOptions.IgnoreCase | RegexOptions.Compiled);
    private static readonly Regex EventHandler = new(@"\s(on\w+)\s*=\s*(""[^""]*""|'[^']*'|[^\s>]+)", RegexOptions.IgnoreCase | RegexOptions.Compiled);
    private static readonly Regex JavascriptUrl = new(@"javascript\s*:", RegexOptions.IgnoreCase | RegexOptions.Compiled);

    public static string Sanitize(string? html)
    {
        if (string.IsNullOrWhiteSpace(html)) return string.Empty;
        var cleaned = ScriptTag.Replace(html, string.Empty);
        cleaned = EventHandler.Replace(cleaned, string.Empty);
        cleaned = JavascriptUrl.Replace(cleaned, string.Empty);
        return cleaned.Trim();
    }
}
