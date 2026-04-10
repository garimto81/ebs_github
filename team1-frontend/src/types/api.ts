export interface PaginationMeta {
  page: number
  limit: number
  total: number
}

export interface ErrorDetail {
  code: string
  message: string
}

export interface ApiResponse<T> {
  data: T | null
  error: ErrorDetail | null
  meta?: PaginationMeta | null
}
