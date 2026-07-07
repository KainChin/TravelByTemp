using Microsoft.EntityFrameworkCore;
using VietAITravel.Api.Constants;
using VietAITravel.Api.Entities;

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

        await SeedTransportConfigsAsync(db, logger);
        await SeedTransportHubsAsync(db, logger);

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
        await EnsureUser("manager", "manager@vietai.travel", "Manager@123", RoleNames.TravelManager, "Content Manager");
        await EnsureUser("traveler", "traveler@vietai.travel", "Traveler@123", RoleNames.Traveler, "Khách du lịch");
        await db.SaveChangesAsync();

        try
        {
            await ContentSeeder.SeedAsync(db, logger);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Content seed skipped.");
        }

        // Embeddings được tạo bởi EmbeddingSeedService sau khi Ollama sẵn sàng.
        logger.LogInformation("User seed completed. Embedding seed runs in background.");
    }

    private static async Task SeedTransportConfigsAsync(AppDbContext db, ILogger logger)
    {
        var defaults = new Dictionary<string, (string Value, string Description)>(StringComparer.OrdinalIgnoreCase)
        {
            ["airportSearchRadiusKm"] = ("80", "Bán kính tìm sân bay gần điểm xuất phát/điểm đến (km)."),
            ["recommendedFlightDistanceKm"] = ("700", "Khoảng cách tối thiểu để ưu tiên gợi ý máy bay (km)."),
            ["shortFlightDistanceKm"] = ("300", "Dưới ngưỡng này máy bay bị đánh dấu không khuyến nghị (km)."),
            ["railSearchRadiusKm"] = ("40", "Bán kính tìm ga tàu hỏa (km)."),
            ["ferryPortSearchRadiusKm"] = ("30", "Bán kính tìm cảng/bến phà (km)."),
        };

        var existing = await db.TransportConfigs.ToListAsync();
        var hasChanges = false;
        foreach (var (key, def) in defaults)
        {
            var row = existing.FirstOrDefault(x => string.Equals(x.Key, key, StringComparison.OrdinalIgnoreCase));
            if (row is null)
            {
                db.TransportConfigs.Add(new TransportConfig
                {
                    Id = Guid.NewGuid(),
                    Key = key,
                    Value = def.Value,
                    Description = def.Description,
                    IsActive = true,
                    UpdatedAt = DateTime.UtcNow,
                });
                hasChanges = true;
            }
            else if (string.IsNullOrWhiteSpace(row.Value))
            {
                row.Value = def.Value;
                row.Description = def.Description;
                row.IsActive = true;
                row.UpdatedAt = DateTime.UtcNow;
                hasChanges = true;
            }
        }

        if (hasChanges)
        {
            await db.SaveChangesAsync();
            logger.LogInformation("Seeded transport_configs defaults.");
        }
    }

    private static async Task SeedTransportHubsAsync(AppDbContext db, ILogger logger)
    {
        if (await db.TransportHubs.AnyAsync()) return;

        var now = DateTime.UtcNow;
        var hubs = new List<TransportHub>
        {
            // ── Airports (Vietnam) ──
            new() { Id = Guid.NewGuid(), Code = "SGN", Name = "Sân bay Tân Sơn Nhất", Type = "airport", Province = "TP. Hồ Chí Minh", Region = "Miền Nam", Latitude = 10.8188, Longitude = 106.6519, Description = "Sân bay quốc tế lớn nhất miền Nam.", CreatedAt = now },
            new() { Id = Guid.NewGuid(), Code = "HAN", Name = "Sân bay Nội Bài", Type = "airport", Province = "Hà Nội", Region = "Miền Bắc", Latitude = 21.2212, Longitude = 105.8070, Description = "Sân bay quốc tế lớn nhất miền Bắc.", CreatedAt = now },
            new() { Id = Guid.NewGuid(), Code = "DAD", Name = "Sân bay Đà Nẵng", Type = "airport", Province = "Đà Nẵng", Region = "Miền Trung", Latitude = 16.0439, Longitude = 108.1994, Description = "Sân bay quốc tế miền Trung.", CreatedAt = now },
            new() { Id = Guid.NewGuid(), Code = "CXR", Name = "Sân bay Cam Ranh", Type = "airport", Province = "Khánh Hòa", Region = "Miền Trung", Latitude = 11.9981, Longitude = 109.2194, Description = "Phục vụ Nha Trang - Khánh Hòa.", CreatedAt = now },
            new() { Id = Guid.NewGuid(), Code = "PQC", Name = "Sân bay Phú Quốc", Type = "airport", Province = "Kiên Giang", Region = "Miền Nam", Latitude = 10.1698, Longitude = 103.9931, Description = "Sân bay đảo Phú Quốc.", CreatedAt = now },
            new() { Id = Guid.NewGuid(), Code = "HPH", Name = "Sân bay Cát Bi", Type = "airport", Province = "Hải Phòng", Region = "Miền Bắc", Latitude = 20.8194, Longitude = 106.7249, Description = "Sân bay quốc tế Hải Phòng.", CreatedAt = now },
            new() { Id = Guid.NewGuid(), Code = "VII", Name = "Sân bay Vinh", Type = "airport", Province = "Nghệ An", Region = "Miền Bắc", Latitude = 18.7376, Longitude = 105.6709, Description = "Sân bay Nghệ An.", CreatedAt = now },
            new() { Id = Guid.NewGuid(), Code = "HUI", Name = "Sân bay Phú Bài", Type = "airport", Province = "Thừa Thiên Huế", Region = "Miền Trung", Latitude = 16.4015, Longitude = 107.7026, Description = "Sân bay Huế.", CreatedAt = now },
            new() { Id = Guid.NewGuid(), Code = "UIH", Name = "Sân bay Phù Cát", Type = "airport", Province = "Bình Định", Region = "Miền Trung", Latitude = 13.9550, Longitude = 109.0425, Description = "Sân bay Quy Nhơn.", CreatedAt = now },
            new() { Id = Guid.NewGuid(), Code = "DLI", Name = "Sân bay Liên Khương", Type = "airport", Province = "Lâm Đồng", Region = "Miền Trung", Latitude = 11.7500, Longitude = 108.3667, Description = "Sân bay Đà Lạt.", CreatedAt = now },
            new() { Id = Guid.NewGuid(), Code = "BMV", Name = "Sân bay Buôn Ma Thuột", Type = "airport", Province = "Đắk Lắk", Region = "Miền Trung", Latitude = 12.6683, Longitude = 108.1200, Description = "Sân bay Buôn Ma Thuột.", CreatedAt = now },
            new() { Id = Guid.NewGuid(), Code = "VCA", Name = "Sân bay Cần Thơ", Type = "airport", Province = "Cần Thơ", Region = "Miền Nam", Latitude = 10.0851, Longitude = 105.7117, Description = "Sân bay Cần Thơ.", CreatedAt = now },

            // ── Train stations (ga chính) ──
            new() { Id = Guid.NewGuid(), Code = "GAHN", Name = "Ga Hà Nội", Type = "train_station", Province = "Hà Nội", Region = "Miền Bắc", Latitude = 21.0245, Longitude = 105.8412, Description = "Ga trung tâm Hà Nội.", CreatedAt = now },
            new() { Id = Guid.NewGuid(), Code = "GASGN", Name = "Ga Sài Gòn", Type = "train_station", Province = "TP. Hồ Chí Minh", Region = "Miền Nam", Latitude = 10.7864, Longitude = 106.6497, Description = "Ga trung tâm TP.HCM.", CreatedAt = now },
            new() { Id = Guid.NewGuid(), Code = "GADAD", Name = "Ga Đà Nẵng", Type = "train_station", Province = "Đà Nẵng", Region = "Miền Trung", Latitude = 16.0731, Longitude = 108.2138, Description = "Ga Đà Nẵng.", CreatedAt = now },
            new() { Id = Guid.NewGuid(), Code = "GAHUI", Name = "Ga Huế", Type = "train_station", Province = "Thừa Thiên Huế", Region = "Miền Trung", Latitude = 16.4637, Longitude = 107.5868, Description = "Ga Huế.", CreatedAt = now },
            new() { Id = Guid.NewGuid(), Code = "GANHA", Name = "Ga Nha Trang", Type = "train_station", Province = "Khánh Hòa", Region = "Miền Trung", Latitude = 12.2388, Longitude = 109.1967, Description = "Ga Nha Trang.", CreatedAt = now },
            new() { Id = Guid.NewGuid(), Code = "GAQNI", Name = "Ga Quy Nhơn", Type = "train_station", Province = "Bình Định", Region = "Miền Trung", Latitude = 13.7820, Longitude = 109.2196, Description = "Ga Quy Nhơn.", CreatedAt = now },

            // ── Ferry ports ──
            new() { Id = Guid.NewGuid(), Code = "FTHN", Name = "Cảng tàu cao tốc Hạ Long", Type = "ferry_port", Province = "Quảng Ninh", Region = "Miền Bắc", Latitude = 20.9553, Longitude = 107.0786, Description = "Cảng Hạ Long - Cát Bà.", CreatedAt = now },
            new() { Id = Guid.NewGuid(), Code = "FKTM", Name = "Cảng Cần Thơ - Côn Đảo", Type = "ferry_port", Province = "Cần Thơ", Region = "Miền Nam", Latitude = 10.0341, Longitude = 105.7841, Description = "Cảng Trần Đề (Sóc Trăng) phục vụ Côn Đảo.", CreatedAt = now },
            new() { Id = Guid.NewGuid(), Code = "FVTA", Name = "Cảng Cầu Đá (Vũng Tàu)", Type = "ferry_port", Province = "Bà Rịa - Vũng Tàu", Region = "Miền Nam", Latitude = 10.3538, Longitude = 107.0847, Description = "Cảng khách Vũng Tàu (chỉ phà/biển nội địa).", CreatedAt = now },
            new() { Id = Guid.NewGuid(), Code = "FDAD", Name = "Cảng Đà Nẵng", Type = "ferry_port", Province = "Đà Nẵng", Region = "Miền Trung", Latitude = 16.1232, Longitude = 108.2244, Description = "Cảng Tiên Sa - phà ra đảo.", CreatedAt = now },
            new() { Id = Guid.NewGuid(), Code = "FNT", Name = "Cảng Nha Trang", Type = "ferry_port", Province = "Khánh Hòa", Region = "Miền Trung", Latitude = 12.2451, Longitude = 109.1948, Description = "Cảng Cầu Đất, Nha Trang.", CreatedAt = now },
        };

        db.TransportHubs.AddRange(hubs);
        await db.SaveChangesAsync();
        logger.LogInformation("Seeded {Count} transport hubs (airports/train stations/ferry ports).", hubs.Count);
    }
}
