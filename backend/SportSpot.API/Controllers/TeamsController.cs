using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SportSpot.Services.DTOs;
using SportSpot.Services.Implementations;

namespace SportSpot.API.Controllers;

[ApiController, Authorize, Route("api/teams")]
public class TeamsController(TeamService service) : ControllerBase
{
    private int UserId => int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var id) ? id : 0;
    [HttpGet("mine")] public async Task<IActionResult> Mine() => Respond(await service.MyTeams(UserId));
    [HttpPost] public async Task<IActionResult> Create(CreateTeamRequest request) => Respond(await service.CreateTeam(UserId, request));
    [HttpGet("challenges"), AllowAnonymous] public async Task<IActionResult> List() => Respond(await service.List(UserId, false));
    [HttpGet("challenges/mine")] public async Task<IActionResult> MyChallenges() => Respond(await service.List(UserId, true));
    [HttpPost("challenges")] public async Task<IActionResult> Open(CreateTeamChallengeRequest request) => Respond(await service.CreateChallenge(UserId, request));
    [HttpPost("challenges/{id:int}/apply")] public async Task<IActionResult> Apply(int id, ApplyTeamChallengeRequest request) => Respond(await service.Apply(UserId, id, request));
    [HttpPost("challenges/{id:int}/requests/{requestId:int}/accept")] public async Task<IActionResult> Accept(int id, int requestId) => Respond(await service.Decide(UserId, id, requestId, true));
    [HttpPost("challenges/{id:int}/requests/{requestId:int}/reject")] public async Task<IActionResult> Reject(int id, int requestId) => Respond(await service.Decide(UserId, id, requestId, false));
    [HttpPost("challenges/{id:int}/requests/{requestId:int}/withdraw")] public async Task<IActionResult> Withdraw(int id, int requestId) => Respond(await service.Withdraw(UserId, id, requestId));
    [HttpPost("challenges/{id:int}/cancel")] public async Task<IActionResult> Cancel(int id) => Respond(await service.Cancel(UserId, id));
    private ObjectResult Respond<T>(ApiResponse<T> result) => StatusCode(result.StatusCode, result);
}
