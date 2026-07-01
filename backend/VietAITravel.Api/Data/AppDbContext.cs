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
    public DbSet<UserFavorite> UserFavorites => Set<UserFavorite>();
    public DbSet<AiItinerary> AiItineraries => Set<AiItinerary>();
    public DbSet<TripRoute> TripRoutes => Set<TripRoute>();
    public DbSet<TripRouteLeg> TripRouteLegs => Set<TripRouteLeg>();
    public DbSet<TransportHub> TransportHubs => Set<TransportHub>();
    public DbSet<TransportRoute> TransportRoutes => Set<TransportRoute>();
    public DbSet<TransportConfig> TransportConfigs => Set<TransportConfig>();
    public DbSet<UserTravelMemory> UserTravelMemories => Set<UserTravelMemory>();

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
            e.Property(x => x.Bio).HasColumnName("bio");
            e.Property(x => x.Phone).HasColumnName("phone");
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

        modelBuilder.Entity<UserFavorite>(e =>
        {
            e.ToTable("user_favorites");
            e.Property(x => x.Id).HasColumnName("id");
            e.Property(x => x.UserId).HasColumnName("user_id");
            e.Property(x => x.DestinationId).HasColumnName("destination_id");
            e.Property(x => x.CreatedAt).HasColumnName("created_at");
            e.HasIndex(x => new { x.UserId, x.DestinationId }).IsUnique();
            e.HasOne(x => x.User).WithMany().HasForeignKey(x => x.UserId).OnDelete(DeleteBehavior.Cascade);
            e.HasOne(x => x.Destination).WithMany().HasForeignKey(x => x.DestinationId).OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<AiItinerary>(e =>
        {
            e.ToTable("ai_itineraries");
            e.Property(x => x.Id).HasColumnName("id");
            e.Property(x => x.UserId).HasColumnName("user_id");
            e.Property(x => x.Title).HasColumnName("title");
            e.Property(x => x.RequestJson).HasColumnName("request_json").HasColumnType("jsonb");
            e.Property(x => x.ItineraryJson).HasColumnName("itinerary_json").HasColumnType("jsonb");
            e.Property(x => x.AiModel).HasColumnName("ai_model");
            e.Property(x => x.CreatedAt).HasColumnName("created_at");
            e.HasOne(x => x.User).WithMany().HasForeignKey(x => x.UserId).OnDelete(DeleteBehavior.SetNull);
        });

        modelBuilder.Entity<TripRoute>(e =>
        {
            e.ToTable("trip_routes");
            e.Property(x => x.Id).HasColumnName("id");
            e.Property(x => x.UserId).HasColumnName("user_id");
            e.Property(x => x.DepartureName).HasColumnName("departure_name");
            e.Property(x => x.DepartureLatitude).HasColumnName("departure_latitude");
            e.Property(x => x.DepartureLongitude).HasColumnName("departure_longitude");
            e.Property(x => x.TotalDistanceKm).HasColumnName("total_distance_km");
            e.Property(x => x.OptimizedHours).HasColumnName("optimized_hours");
            e.Property(x => x.PeopleCount).HasColumnName("people_count");
            e.Property(x => x.BudgetPerPerson).HasColumnName("budget_per_person");
            e.Property(x => x.HasFlightLeg).HasColumnName("has_flight_leg");
            e.Property(x => x.CreatedAt).HasColumnName("created_at");
            e.HasOne(x => x.User).WithMany().HasForeignKey(x => x.UserId).OnDelete(DeleteBehavior.SetNull);
            e.HasMany(x => x.Legs).WithOne(x => x.Route).HasForeignKey(x => x.TripRouteId).OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<TripRouteLeg>(e =>
        {
            e.ToTable("trip_route_legs");
            e.Property(x => x.Id).HasColumnName("id");
            e.Property(x => x.TripRouteId).HasColumnName("trip_route_id");
            e.Property(x => x.LegOrder).HasColumnName("leg_order");
            e.Property(x => x.FromName).HasColumnName("from_name");
            e.Property(x => x.ToName).HasColumnName("to_name");
            e.Property(x => x.ToRegion).HasColumnName("to_region");
            e.Property(x => x.ToLatitude).HasColumnName("to_latitude");
            e.Property(x => x.ToLongitude).HasColumnName("to_longitude");
            e.Property(x => x.DistanceKm).HasColumnName("distance_km");
            e.Property(x => x.DurationHours).HasColumnName("duration_hours");
            e.Property(x => x.RecommendedMode).HasColumnName("recommended_mode");
            e.Property(x => x.Reason).HasColumnName("reason");
            e.Property(x => x.IsGoogleEstimate).HasColumnName("is_google_estimate");
            e.HasIndex(x => new { x.TripRouteId, x.LegOrder }).IsUnique();
        });

        modelBuilder.Entity<TransportHub>(e =>
        {
            e.ToTable("transport_hubs");
            e.Property(x => x.Id).HasColumnName("id");
            e.Property(x => x.Code).HasColumnName("code");
            e.Property(x => x.Name).HasColumnName("name");
            e.Property(x => x.Type).HasColumnName("type");
            e.Property(x => x.Province).HasColumnName("province");
            e.Property(x => x.Region).HasColumnName("region");
            e.Property(x => x.Latitude).HasColumnName("latitude");
            e.Property(x => x.Longitude).HasColumnName("longitude");
            e.Property(x => x.Description).HasColumnName("description");
            e.Property(x => x.IsActive).HasColumnName("is_active");
            e.Property(x => x.CreatedAt).HasColumnName("created_at");
            e.HasIndex(x => x.Code).IsUnique();
            e.HasIndex(x => new { x.Type, x.IsActive });
        });

        modelBuilder.Entity<TransportRoute>(e =>
        {
            e.ToTable("transport_routes");
            e.Property(x => x.Id).HasColumnName("id");
            e.Property(x => x.OriginHubId).HasColumnName("origin_hub_id");
            e.Property(x => x.DestinationHubId).HasColumnName("destination_hub_id");
            e.Property(x => x.TransportType).HasColumnName("transport_type");
            e.Property(x => x.EstimatedDurationHours).HasColumnName("estimated_duration_hours");
            e.Property(x => x.EstimatedCostVnd).HasColumnName("estimated_cost_vnd");
            e.Property(x => x.IsActive).HasColumnName("is_active");
            e.Property(x => x.CreatedAt).HasColumnName("created_at");
            e.HasIndex(x => new { x.OriginHubId, x.DestinationHubId, x.TransportType }).IsUnique();
            e.HasOne(x => x.OriginHub).WithMany(x => x.OriginRoutes).HasForeignKey(x => x.OriginHubId).OnDelete(DeleteBehavior.Restrict);
            e.HasOne(x => x.DestinationHub).WithMany(x => x.DestinationRoutes).HasForeignKey(x => x.DestinationHubId).OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<TransportConfig>(e =>
        {
            e.ToTable("transport_configs");
            e.Property(x => x.Id).HasColumnName("id");
            e.Property(x => x.Key).HasColumnName("key");
            e.Property(x => x.Value).HasColumnName("value");
            e.Property(x => x.Description).HasColumnName("description");
            e.Property(x => x.IsActive).HasColumnName("is_active");
            e.Property(x => x.UpdatedAt).HasColumnName("updated_at");
            e.HasIndex(x => x.Key).IsUnique();
        });

        modelBuilder.Entity<UserTravelMemory>(e =>
        {
            e.ToTable("user_travel_memories");
            e.Property(x => x.Id).HasColumnName("id");
            e.Property(x => x.UserId).HasColumnName("user_id");
            e.Property(x => x.PreferredStylesJson).HasColumnName("preferred_styles_json").HasColumnType("jsonb");
            e.Property(x => x.PreferredTransport).HasColumnName("preferred_transport");
            e.Property(x => x.AverageBudget).HasColumnName("average_budget");
            e.Property(x => x.TripCount).HasColumnName("trip_count");
            e.Property(x => x.Notes).HasColumnName("notes");
            e.Property(x => x.CreatedAt).HasColumnName("created_at");
            e.Property(x => x.UpdatedAt).HasColumnName("updated_at");
            e.HasIndex(x => x.UserId).IsUnique();
            e.HasOne(x => x.User).WithMany().HasForeignKey(x => x.UserId).OnDelete(DeleteBehavior.Cascade);
        });
    }
}
