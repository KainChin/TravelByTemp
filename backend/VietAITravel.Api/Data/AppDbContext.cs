using Microsoft.EntityFrameworkCore;
using VietAITravel.Api.Entities;

namespace VietAITravel.Api.Data;

public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<Role> Roles => Set<Role>();
    public DbSet<User> Users => Set<User>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();
    public DbSet<Destination> Destinations => Set<Destination>();
    public DbSet<Schedule> Schedules => Set<Schedule>();
    public DbSet<ScheduleDestination> ScheduleDestinations => Set<ScheduleDestination>();
    public DbSet<Comment> Comments => Set<Comment>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.HasPostgresExtension("vector");
        modelBuilder.HasPostgresExtension("pgcrypto");

        modelBuilder.Entity<Role>(e =>
        {
            e.ToTable("roles");
            e.Property(x => x.Id).HasColumnName("id");
            e.Property(x => x.Name).HasColumnName("name");
            e.Property(x => x.Description).HasColumnName("description");
            e.Property(x => x.CreatedAt).HasColumnName("created_at");
        });

        modelBuilder.Entity<User>(e =>
        {
            e.ToTable("users");
            e.Property(x => x.Id).HasColumnName("id");
            e.Property(x => x.RoleId).HasColumnName("role_id");
            e.Property(x => x.Username).HasColumnName("username");
            e.Property(x => x.Email).HasColumnName("email");
            e.Property(x => x.PasswordHash).HasColumnName("password_hash");
            e.Property(x => x.FullName).HasColumnName("full_name");
            e.Property(x => x.AvatarUrl).HasColumnName("avatar_url");
            e.Property(x => x.IsActive).HasColumnName("is_active");
            e.Property(x => x.CreatedAt).HasColumnName("created_at");
            e.Property(x => x.UpdatedAt).HasColumnName("updated_at");
            e.HasOne(x => x.Role).WithMany(r => r.Users).HasForeignKey(x => x.RoleId);
        });

        modelBuilder.Entity<RefreshToken>(e =>
        {
            e.ToTable("refresh_tokens");
            e.Property(x => x.Id).HasColumnName("id");
            e.Property(x => x.UserId).HasColumnName("user_id");
            e.Property(x => x.Token).HasColumnName("token");
            e.Property(x => x.ExpiresAt).HasColumnName("expires_at");
            e.Property(x => x.IsRevoked).HasColumnName("is_revoked");
            e.Property(x => x.CreatedAt).HasColumnName("created_at");
            e.HasOne(x => x.User).WithMany().HasForeignKey(x => x.UserId).OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<Destination>(e =>
        {
            e.ToTable("destinations");
            e.Property(x => x.Id).HasColumnName("id");
            e.Property(x => x.Name).HasColumnName("name");
            e.Property(x => x.Slug).HasColumnName("slug");
            e.Property(x => x.Description).HasColumnName("description");
            e.Property(x => x.Province).HasColumnName("province");
            e.Property(x => x.Region).HasColumnName("region");
            e.Property(x => x.Latitude).HasColumnName("latitude");
            e.Property(x => x.Longitude).HasColumnName("longitude");
            e.Property(x => x.Category).HasColumnName("category");
            e.Property(x => x.EstimatedCost).HasColumnName("estimated_cost");
            e.Property(x => x.CostUnit).HasColumnName("cost_unit");
            e.Property(x => x.OpeningHours).HasColumnName("opening_hours");
            e.Property(x => x.ImageUrl).HasColumnName("image_url");
            e.Property(x => x.BestTimeToVisit).HasColumnName("best_time_to_visit");
            e.Property(x => x.SuitableWeather).HasColumnName("suitable_weather");
            e.Property(x => x.TravelStyle).HasColumnName("travel_style");
            e.Property(x => x.AiRecommendationNote).HasColumnName("ai_recommendation_note");
            e.Property(x => x.EmbeddingText).HasColumnName("embedding_text");
            e.Property(x => x.Embedding).HasColumnName("embedding");
            e.Property(x => x.IsActive).HasColumnName("is_active");
            e.Property(x => x.CreatedAt).HasColumnName("created_at");
            e.Property(x => x.UpdatedAt).HasColumnName("updated_at");
        });

        modelBuilder.Entity<Schedule>(e =>
        {
            e.ToTable("schedules");
            e.Property(x => x.Id).HasColumnName("id");
            e.Property(x => x.UserId).HasColumnName("user_id");
            e.Property(x => x.Title).HasColumnName("title");
            e.Property(x => x.TotalDays).HasColumnName("total_days");
            e.Property(x => x.BudgetInput).HasColumnName("budget_input");
            e.Property(x => x.PreferenceInput).HasColumnName("preference_input");
            e.Property(x => x.UserLatitude).HasColumnName("user_latitude");
            e.Property(x => x.UserLongitude).HasColumnName("user_longitude");
            e.Property(x => x.UserLocationName).HasColumnName("user_location_name");
            e.Property(x => x.CurrentTemperature).HasColumnName("current_temperature");
            e.Property(x => x.CurrentWeatherDescription).HasColumnName("current_weather_description");
            e.Property(x => x.MongoAiLogId).HasColumnName("mongo_ai_log_id");
            e.Property(x => x.AiModelUsed).HasColumnName("ai_model_used");
            e.Property(x => x.EmbeddingModelUsed).HasColumnName("embedding_model_used");
            e.Property(x => x.IsPublic).HasColumnName("is_public");
            e.Property(x => x.GeneratedAt).HasColumnName("generated_at");
            e.Property(x => x.UpdatedAt).HasColumnName("updated_at");
            e.HasOne(x => x.User).WithMany(u => u.Schedules).HasForeignKey(x => x.UserId).OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<ScheduleDestination>(e =>
        {
            e.ToTable("schedule_destinations");
            e.Property(x => x.Id).HasColumnName("id");
            e.Property(x => x.ScheduleId).HasColumnName("schedule_id");
            e.Property(x => x.DestinationId).HasColumnName("destination_id");
            e.Property(x => x.DayNumber).HasColumnName("day_number");
            e.Property(x => x.OrderInDay).HasColumnName("order_in_day");
            e.Property(x => x.Note).HasColumnName("note");
            e.Property(x => x.EstimatedTime).HasColumnName("estimated_time");
            e.Property(x => x.AiReason).HasColumnName("ai_reason");
            e.Property(x => x.WeatherFitNote).HasColumnName("weather_fit_note");
            e.HasIndex(x => new { x.ScheduleId, x.DayNumber, x.OrderInDay }).IsUnique();
            e.HasOne(x => x.Schedule).WithMany(s => s.ScheduleDestinations).HasForeignKey(x => x.ScheduleId).OnDelete(DeleteBehavior.Cascade);
            e.HasOne(x => x.Destination).WithMany().HasForeignKey(x => x.DestinationId).OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<Comment>(e =>
        {
            e.ToTable("comments");
            e.Property(x => x.Id).HasColumnName("id");
            e.Property(x => x.UserId).HasColumnName("user_id");
            e.Property(x => x.DestinationId).HasColumnName("destination_id");
            e.Property(x => x.Rating).HasColumnName("rating");
            e.Property(x => x.Content).HasColumnName("content");
            e.Property(x => x.IsApproved).HasColumnName("is_approved");
            e.Property(x => x.CreatedAt).HasColumnName("created_at");
            e.Property(x => x.UpdatedAt).HasColumnName("updated_at");
            e.HasIndex(x => new { x.UserId, x.DestinationId }).IsUnique();
            e.HasOne(x => x.User).WithMany().HasForeignKey(x => x.UserId).OnDelete(DeleteBehavior.Restrict);
            e.HasOne(x => x.Destination).WithMany().HasForeignKey(x => x.DestinationId).OnDelete(DeleteBehavior.Cascade);
        });
    }
}
