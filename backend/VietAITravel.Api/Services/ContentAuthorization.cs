using System.Security.Claims;
using VietAITravel.Api.Constants;

namespace VietAITravel.Api.Services;

public static class ContentAuthorization
{
    public static bool CanPublish(ClaimsPrincipal user) =>
        user.IsInRole(RoleNames.Admin);

    public static bool CanManageUsers(ClaimsPrincipal user) =>
        user.IsInRole(RoleNames.Admin);

    public static void EnsureCanPublish(ClaimsPrincipal user)
    {
        if (!CanPublish(user))
            throw new UnauthorizedAccessException("Chỉ Admin mới được xuất bản nội dung.");
    }

    public static string NormalizeStatus(string? requestedStatus, ClaimsPrincipal user, string currentStatus)
    {
        if (string.IsNullOrWhiteSpace(requestedStatus))
            return currentStatus;

        if (requestedStatus == "published" && !CanPublish(user))
            return currentStatus == "published" ? "published" : "pending";

        return requestedStatus;
    }
}
