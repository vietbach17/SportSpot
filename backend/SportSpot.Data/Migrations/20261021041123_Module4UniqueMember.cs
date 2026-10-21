using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SportSpot.Data.Migrations
{
    /// <inheritdoc />
    public partial class Module4UniqueMember : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_MatchMembers_MatchId",
                table: "MatchMembers");

            migrationBuilder.CreateIndex(
                name: "IX_MatchMembers_MatchId_UserId",
                table: "MatchMembers",
                columns: new[] { "MatchId", "UserId" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_MatchMembers_MatchId_UserId",
                table: "MatchMembers");

            migrationBuilder.CreateIndex(
                name: "IX_MatchMembers_MatchId",
                table: "MatchMembers",
                column: "MatchId");
        }
    }
}
