namespace VietAITravel.Api.Entities;

public class TripRoute
{
    public Guid Id { get; set; }
    public Guid? UserId { get; set; }
    public string DepartureName { get; set; } = "";
    public double DepartureLatitude { get; set; }
    public double DepartureLongitude { get; set; }
    public double TotalDistanceKm { get; set; }
    public double OptimizedHours { get; set; }
    public int? PeopleCount { get; set; }
    public decimal? BudgetPerPerson { get; set; }
    public bool HasFlightLeg { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public User? User { get; set; }
    public ICollection<TripRouteLeg> Legs { get; set; } = new List<TripRouteLeg>();
}
