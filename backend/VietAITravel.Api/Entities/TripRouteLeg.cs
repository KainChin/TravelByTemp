namespace VietAITravel.Api.Entities;

public class TripRouteLeg
{
    public Guid Id { get; set; }
    public Guid TripRouteId { get; set; }
    public int LegOrder { get; set; }
    public string FromName { get; set; } = "";
    public string ToName { get; set; } = "";
    public string ToRegion { get; set; } = "";
    public double ToLatitude { get; set; }
    public double ToLongitude { get; set; }
    public double DistanceKm { get; set; }
    public double DurationHours { get; set; }
    public string RecommendedMode { get; set; } = "";
    public string Reason { get; set; } = "";
    public bool IsGoogleEstimate { get; set; }

    public TripRoute? Route { get; set; }
}
