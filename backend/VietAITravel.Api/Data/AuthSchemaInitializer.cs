using Microsoft.EntityFrameworkCore;

namespace VietAITravel.Api.Data;

public static class AuthSchemaInitializer
{
    public static async Task EnsureAsync(IServiceProvider services)
    {
        using var scope = services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        if (!await db.Database.CanConnectAsync()) return;

        await db.Database.ExecuteSqlRawAsync("""
            ALTER TABLE users ALTER COLUMN email DROP NOT NULL;

            CREATE TABLE IF NOT EXISTS auth_verification_codes (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                purpose VARCHAR(40) NOT NULL,
                username VARCHAR(50) NOT NULL,
                email VARCHAR(255),
                phone VARCHAR(30),
                full_name VARCHAR(150) NOT NULL,
                password_hash VARCHAR(500) NOT NULL,
                code_hash VARCHAR(500) NOT NULL,
                expires_at TIMESTAMP NOT NULL,
                consumed_at TIMESTAMP,
                attempts INT NOT NULL DEFAULT 0,
                created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
            );

            ALTER TABLE auth_verification_codes ALTER COLUMN email DROP NOT NULL;
            """);
    }
}
