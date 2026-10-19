namespace SportSpot.API.DTOs;

public class ApiResponse<T>
{
    public bool Success { get; set; }
    public int StatusCode { get; set; }
    public string Message { get; set; } = string.Empty;
    public T? Data { get; set; }

    public static ApiResponse<T> Ok(T data, string message = "Thành công")
    {
        return new ApiResponse<T>
        {
            Success = true,
            StatusCode = 200,
            Message = message,
            Data = data
        };
    }

    public static ApiResponse<T> Created(T data, string message = "Tạo thành công")
    {
        return new ApiResponse<T>
        {
            Success = true,
            StatusCode = 201,
            Message = message,
            Data = data
        };
    }

    public static ApiResponse<T> Fail(string message, int statusCode = 400)
    {
        return new ApiResponse<T>
        {
            Success = false,
            StatusCode = statusCode,
            Message = message,
            Data = default
        };
    }
}
