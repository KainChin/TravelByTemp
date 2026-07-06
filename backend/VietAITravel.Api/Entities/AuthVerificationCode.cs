namespace VietAITravel.Api.Entities;

public class AuthVerificationCode
{
    public Guid Id { get; set; }
    public string Purpose { get; set; } = null!;
    public string Username { get; set; } = null!;
    public string? Email { get; set; }
    public string? Phone { get; set; }
    public string FullName { get; set; } = null!;
    public string PasswordHash { get; set; } = null!;
    public string CodeHash { get; set; } = null!;
    public DateTime ExpiresAt { get; set; }
    public DateTime? ConsumedAt { get; set; }
    public int Attempts { get; set; }
    public DateTime CreatedAt { get; set; }
}
