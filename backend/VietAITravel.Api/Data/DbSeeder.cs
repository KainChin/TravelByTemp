using Microsoft.EntityFrameworkCore;
using VietAITravel.Api.Constants;
using VietAITravel.Api.Entities;
using VietAITravel.Api.Services;

namespace VietAITravel.Api.Data;

public static class DbSeeder
{
    public static async Task SeedAsync(IServiceProvider services, IConfiguration config)
    {
        if (!bool.TryParse(config["Seed:RunOnStartup"], out var run) || !run)
            return;

        using var scope = services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var logger = scope.ServiceProvider.GetRequiredService<ILogger<AppDbContext>>();

        if (!await db.Database.CanConnectAsync())
        {
            logger.LogWarning("PostgreSQL not ready, skipping seed.");
            return;
        }

        var roles = await db.Roles.ToListAsync();
        if (roles.Count == 0)
        {
            db.Roles.AddRange(
                new Role { Id = Guid.NewGuid(), Name = RoleNames.Admin, Description = "Admin", CreatedAt = DateTime.UtcNow },
                new Role { Id = Guid.NewGuid(), Name = RoleNames.TravelManager, Description = "Manager", CreatedAt = DateTime.UtcNow },
                new Role { Id = Guid.NewGuid(), Name = RoleNames.Traveler, Description = "Traveler", CreatedAt = DateTime.UtcNow });
            await db.SaveChangesAsync();
            roles = await db.Roles.ToListAsync();
        }

        async Task EnsureUser(string username, string email, string password, string roleName, string fullName)
        {
            if (await db.Users.AnyAsync(u => u.Username == username)) return;
            var role = roles.First(r => r.Name == roleName);
            db.Users.Add(new User
            {
                Id = Guid.NewGuid(),
                RoleId = role.Id,
                Username = username,
                Email = email,
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(password),
                FullName = fullName,
                IsActive = true,
                CreatedAt = DateTime.UtcNow
            });
        }

        await EnsureUser("admin", "admin@vietai.travel", "Admin@123", RoleNames.Admin, "Quản trị viên");
        await EnsureUser("manager", "manager@vietai.travel", "Manager@123", RoleNames.TravelManager, "Travel Manager");
        await EnsureUser("traveler", "traveler@vietai.travel", "Traveler@123", RoleNames.Traveler, "Khách du lịch");
        await db.SaveChangesAsync();

        // Embeddings được tạo bởi EmbeddingSeedService sau khi Ollama sẵn sàng.
        logger.LogInformation("User seed completed. Embedding seed runs in background.");
    }
}
