namespace VietAITravel.Api.DTOs;

public record FavoriteDestinationDto(
    Guid Id,
    DateTime SavedAt,
    DestinationDto Destination);
