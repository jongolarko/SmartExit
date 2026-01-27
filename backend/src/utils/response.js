// Standard API response helpers

const success = (res, data = {}, statusCode = 200) => {
  return res.status(statusCode).json({
    success: true,
    ...data,
  });
};

const error = (res, message, statusCode = 400, details = null) => {
  const response = {
    success: false,
    error: message,
  };

  if (details) {
    response.details = details;
  }

  return res.status(statusCode).json(response);
};

const paginated = (res, data, page, limit, total) => {
  return res.status(200).json({
    success: true,
    data,
    pagination: {
      page,
      limit,
      total,
      totalPages: Math.ceil(total / limit),
    },
  });
};

module.exports = { success, error, paginated };
