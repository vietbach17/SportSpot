using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SportSpot.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddOpenMatchDetails : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "HostNote",
                table: "OpenMatches",
                type: "character varying(1000)",
                maxLength: 1000,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "HostPhone",
                table: "OpenMatches",
                type: "character varying(20)",
                maxLength: 20,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Title",
                table: "OpenMatches",
                type: "character varying(200)",
                maxLength: 200,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "HostNote",
                table: "OpenMatches");

            migrationBuilder.DropColumn(
                name: "HostPhone",
                table: "OpenMatches");

            migrationBuilder.DropColumn(
                name: "Title",
                table: "OpenMatches");
        }
    }
}
