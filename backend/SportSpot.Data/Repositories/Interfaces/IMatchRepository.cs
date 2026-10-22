using SportSpot.Data.Entities;

namespace SportSpot.Data.Repositories.Interfaces;

public interface IMatchRepository : IGenericRepository<OpenMatch>
{
    Task<List<OpenMatch>> GetOpenMatchesWithDetailsAsync(int? sportId, string? district);
    Task<OpenMatch?> GetMatchByIdWithDetailsAsync(int matchId);
    Task<MatchMember?> GetMatchMemberAsync(int matchId, int userId);
    Task<List<MatchMember>> GetUserJoinedMatchesWithDetailsAsync(int userId);
    Task AddMatchMemberAsync(MatchMember member);
    void RemoveMatchMember(MatchMember member);
}
