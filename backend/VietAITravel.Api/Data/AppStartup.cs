using Microsoft.EntityFrameworkCore;
using VietAITravel.Api.Services;

namespace VietAITravel.Api.Data;

public static class AppStartup
{
    /// <summary>Always ensure CMS tables exist — independent of demo seed flag.</summary>
    public static async Task EnsureDatabaseReadyAsync(IServiceProvider services)
    {
        using var scope = services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var logger = scope.ServiceProvider.GetRequiredService<ILogger<AppDbContext>>();

        if (!await db.Database.CanConnectAsync())
        {
            logger.LogWarning("PostgreSQL not ready, skipping schema bootstrap.");
            return;
        }

        await SchemaBootstrapper.EnsureContentSchemaAsync(db, logger);
    }
}
