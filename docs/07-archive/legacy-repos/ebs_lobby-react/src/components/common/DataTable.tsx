import { type ReactNode } from 'react'
import LoadingSpinner from './LoadingSpinner'

export interface Column<T> {
  header: string
  accessor: keyof T | ((row: T) => ReactNode)
  render?: (value: unknown, row: T) => ReactNode
}

interface DataTableProps<T> {
  columns: Column<T>[]
  data: T[]
  loading?: boolean
  emptyMessage?: string
  onRowClick?: (row: T) => void
  page?: number
  totalPages?: number
  onPageChange?: (page: number) => void
}

export default function DataTable<T>({
  columns,
  data,
  loading,
  emptyMessage = 'No data',
  onRowClick,
  page,
  totalPages,
  onPageChange,
}: DataTableProps<T>) {
  if (loading) return <LoadingSpinner />

  return (
    <div className="data-table-wrapper">
      <table className="data-table">
        <thead>
          <tr>
            {columns.map((col, i) => (
              <th key={i}>{col.header}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {data.length === 0 ? (
            <tr>
              <td colSpan={columns.length} className="empty-row">{emptyMessage}</td>
            </tr>
          ) : (
            data.map((row, rowIndex) => (
              <tr
                key={rowIndex}
                onClick={() => onRowClick?.(row)}
                className={onRowClick ? 'clickable' : ''}
              >
                {columns.map((col, colIndex) => {
                  const value = typeof col.accessor === 'function'
                    ? col.accessor(row)
                    : row[col.accessor]
                  return (
                    <td key={colIndex}>
                      {col.render ? col.render(value, row) : (value as ReactNode)}
                    </td>
                  )
                })}
              </tr>
            ))
          )}
        </tbody>
      </table>
      {page !== undefined && totalPages !== undefined && totalPages > 1 && onPageChange && (
        <div className="table-pagination">
          <button
            disabled={page <= 1}
            onClick={() => onPageChange(page - 1)}
          >
            Previous
          </button>
          <span>Page {page} of {totalPages}</span>
          <button
            disabled={page >= totalPages}
            onClick={() => onPageChange(page + 1)}
          >
            Next
          </button>
        </div>
      )}
    </div>
  )
}
