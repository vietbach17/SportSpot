using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SportSpot.Data.Migrations
{
    /// <inheritdoc />
    public partial class Module4Matchmaking : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "StaffVenueId",
                table: "Users",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "Revision",
                table: "OpenMatches",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<string>(
                name: "SkillLevel",
                table: "OpenMatches",
                type: "character varying(30)",
                maxLength: 30,
                nullable: false,
                defaultValue: "Cơ bản");

            migrationBuilder.CreateIndex(
                name: "IX_Users_StaffVenueId",
                table: "Users",
                column: "StaffVenueId");

            migrationBuilder.AddForeignKey(
                name: "FK_Users_Venues_StaffVenueId",
                table: "Users",
                column: "StaffVenueId",
                principalTable: "Venues",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Users_Venues_StaffVenueId",
                table: "Users");

            migrationBuilder.DropIndex(
                name: "IX_Users_StaffVenueId",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "StaffVenueId",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "Revision",
                table: "OpenMatches");

            migrationBuilder.DropColumn(
                name: "SkillLevel",
                table: "OpenMatches");
        }
    }
}
