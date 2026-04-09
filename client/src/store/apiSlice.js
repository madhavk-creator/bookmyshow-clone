import { createApi, fetchBaseQuery } from '@reduxjs/toolkit/query/react'

export const apiSlice = createApi({
  reducerPath: 'api',
  baseQuery: fetchBaseQuery({
    baseUrl: '/',
    prepareHeaders: (headers) => {
      const token = localStorage.getItem('token')

      if (token) {
        headers.set('authorization', `Bearer ${token}`)
      }

      headers.set('content-type', 'application/json')
      return headers
    },
  }),
  tagTypes: ['Booking', 'City', 'Coupon', 'Format', 'Language', 'Movie', 'Review', 'Screen', 'SeatLayout', 'Show', 'Theatre', 'Vendor'],
  endpoints: (builder) => ({
    getCities: builder.query({
      query: () => '/api/v1/cities',
      transformResponse: (response) => Array.isArray(response) ? response : (response?.cities || []),
      providesTags: ['City'],
    }),
    getMovies: builder.query({
      query: (params = {}) => ({
        url: '/api/v1/movies',
        params,
      }),
      transformResponse: (response) => Array.isArray(response) ? response : (response?.movies || []),
      providesTags: ['Movie'],
    }),
    getMovie: builder.query({
      query: (movieId) => `/api/v1/movies/${movieId}`,
      providesTags: (_result, _error, movieId) => [{ type: 'Movie', id: movieId }],
    }),
    getMovieReviews: builder.query({
      query: ({ movieId, perPage = 10 }) => ({
        url: `/api/v1/movies/${movieId}/reviews`,
        params: { per_page: perPage },
      }),
      providesTags: (_result, _error, { movieId }) => [{ type: 'Review', id: movieId }],
    }),
    getLanguages: builder.query({
      query: () => '/api/v1/languages',
      transformResponse: (response) => Array.isArray(response) ? response : (response?.languages || []),
      providesTags: ['Language'],
    }),
    getFormats: builder.query({
      query: () => '/api/v1/formats',
      transformResponse: (response) => Array.isArray(response) ? response : (response?.formats || []),
      providesTags: ['Format'],
    }),
    getShows: builder.query({
      query: (params = {}) => ({
        url: '/api/v1/shows',
        params,
      }),
      transformResponse: (response) => Array.isArray(response) ? response : (response?.shows || []),
      providesTags: ['Show'],
    }),
    getBookings: builder.query({
      query: (params = {}) => ({
        url: '/api/v1/bookings',
        params,
      }),
      providesTags: ['Booking'],
    }),
    getBooking: builder.query({
      query: (bookingId) => `/api/v1/bookings/${bookingId}`,
      providesTags: (_result, _error, bookingId) => [{ type: 'Booking', id: bookingId }],
    }),
    getCoupons: builder.query({
      query: () => '/api/v1/coupons',
      transformResponse: (response) => Array.isArray(response) ? response : (response?.coupons || []),
      providesTags: ['Coupon'],
    }),
    getTheatres: builder.query({
      query: (params = {}) => ({
        url: '/api/v1/theatres',
        params,
      }),
      transformResponse: (response) => Array.isArray(response) ? response : (response?.theatres || []),
      providesTags: ['Theatre'],
    }),
    getTheatre: builder.query({
      query: (theatreId) => `/api/v1/theatres/${theatreId}`,
      providesTags: (_result, _error, theatreId) => [{ type: 'Theatre', id: theatreId }],
    }),
    getScreens: builder.query({
      query: ({ theatreId }) => `/api/v1/theatres/${theatreId}/screens`,
      transformResponse: (response) => Array.isArray(response) ? response : (response?.screens || []),
      providesTags: (_result, _error, { theatreId }) => [{ type: 'Screen', id: `list-${theatreId}` }],
    }),
    getScreen: builder.query({
      query: ({ theatreId, screenId }) => `/api/v1/theatres/${theatreId}/screens/${screenId}`,
      providesTags: (_result, _error, { screenId }) => [{ type: 'Screen', id: screenId }],
    }),
    getScreenShows: builder.query({
      query: ({ theatreId, screenId }) => `/api/v1/theatres/${theatreId}/screens/${screenId}/shows`,
      transformResponse: (response) => response?.shows || response || [],
      providesTags: (_result, _error, { screenId }) => [{ type: 'Show', id: `screen-${screenId}` }],
    }),
    getShow: builder.query({
      query: ({ theatreId, screenId, showId }) =>
        theatreId && screenId
          ? `/api/v1/theatres/${theatreId}/screens/${screenId}/shows/${showId}`
          : `/api/v1/shows/${showId}`,
      providesTags: (_result, _error, { showId }) => [{ type: 'Show', id: showId }],
    }),
    getSeatLayouts: builder.query({
      query: ({ theatreId, screenId }) => `/api/v1/theatres/${theatreId}/screens/${screenId}/seat_layouts`,
      transformResponse: (response) => Array.isArray(response) ? response : (response?.seat_layouts || []),
      providesTags: (_result, _error, { screenId }) => [{ type: 'SeatLayout', id: `screen-${screenId}` }],
    }),
    getSeatLayout: builder.query({
      query: ({ theatreId, screenId, layoutId }) => `/api/v1/theatres/${theatreId}/screens/${screenId}/seat_layouts/${layoutId}`,
      providesTags: (_result, _error, { layoutId }) => [{ type: 'SeatLayout', id: layoutId }],
    }),
    getShowSeats: builder.query({
      query: (showId) => `/api/v1/shows/${showId}/seats`,
      providesTags: (_result, _error, showId) => [{ type: 'Show', id: `seats-${showId}` }],
    }),
    getVendors: builder.query({
      query: () => '/api/v1/vendors',
      transformResponse: (response) => Array.isArray(response) ? response : (response?.vendors || []),
      providesTags: ['Vendor'],
    }),
    getVendorIncome: builder.query({
      query: (vendorId) => `/api/v1/vendors/${vendorId}/income`,
      providesTags: (_result, _error, vendorId) => [{ type: 'Vendor', id: vendorId }],
    }),
    getVendorShowsSummary: builder.query({
      query: (vendorId) => `/api/v1/vendors/${vendorId}/shows_summary`,
      transformResponse: (response) => response?.shows || [],
      providesTags: (_result, _error, vendorId) => [{ type: 'Vendor', id: `shows-${vendorId}` }],
    }),
    getVendorSummaries: builder.query({
      async queryFn(_arg, _api, _extraOptions, fetchWithBQ) {
        const vendorsResult = await fetchWithBQ('/api/v1/vendors')
        if (vendorsResult.error) return { error: vendorsResult.error }

        const vendors = Array.isArray(vendorsResult.data) ? vendorsResult.data : (vendorsResult.data?.vendors || [])
        const incomeResponses = await Promise.all(
          vendors.map(async (vendor) => {
            const incomeResult = await fetchWithBQ(`/api/v1/vendors/${vendor.id}/income`)

            if (incomeResult.error) {
              return {
                id: vendor.id,
                name: vendor.name,
                email: vendor.email,
                theatres_count: vendor.theatres_count ?? 0,
                tickets_sold_count: 0,
                completed_bookings_count: 0,
                total_income: 0,
                gross_income: 0,
                refund_amount: 0,
              }
            }

            const incomeData = incomeResult.data || {}
            return {
              id: vendor.id,
              name: vendor.name,
              email: vendor.email,
              theatres_count: vendor.theatres_count ?? incomeData.theatres_count ?? 0,
              tickets_sold_count: incomeData.tickets_sold_count ?? 0,
              completed_bookings_count: incomeData.completed_bookings_count ?? 0,
              total_income: Number(incomeData.total_income || 0),
              gross_income: Number(incomeData.gross_income || 0),
              refund_amount: Number(incomeData.refund_amount || 0),
            }
          })
        )

        return {
          data: incomeResponses.sort((a, b) => b.total_income - a.total_income),
        }
      },
      providesTags: ['Vendor'],
    }),
    getReferenceItems: builder.query({
      query: (apiPath) => `/api/v1/${apiPath}`,
      transformResponse: (response, _meta, apiPath) => {
        if (Array.isArray(response)) return response
        return response?.[apiPath] || []
      },
      providesTags: (_result, _error, apiPath) => [{ type: 'City', id: apiPath }],
    }),
    createTheatre: builder.mutation({
      query: (theatre) => ({
        url: '/api/v1/theatres',
        method: 'POST',
        body: { theatre },
      }),
      invalidatesTags: ['Theatre', 'Vendor'],
    }),
    updateTheatre: builder.mutation({
      query: ({ id, theatre }) => ({
        url: `/api/v1/theatres/${id}`,
        method: 'PATCH',
        body: { theatre },
      }),
      invalidatesTags: (_result, _error, { id }) => ['Theatre', { type: 'Theatre', id }],
    }),
    deleteTheatre: builder.mutation({
      query: (id) => ({
        url: `/api/v1/theatres/${id}`,
        method: 'DELETE',
      }),
      invalidatesTags: ['Theatre', 'Vendor', 'Screen', 'SeatLayout', 'Show'],
    }),
    createScreen: builder.mutation({
      query: ({ theatreId, screen }) => ({
        url: `/api/v1/theatres/${theatreId}/screens`,
        method: 'POST',
        body: { screen },
      }),
      invalidatesTags: (_result, _error, { theatreId }) => ['Screen', { type: 'Screen', id: `list-${theatreId}` }],
    }),
    updateScreen: builder.mutation({
      query: ({ theatreId, screenId, screen }) => ({
        url: `/api/v1/theatres/${theatreId}/screens/${screenId}`,
        method: 'PATCH',
        body: { screen },
      }),
      invalidatesTags: (_result, _error, { theatreId, screenId }) => ['Screen', { type: 'Screen', id: `list-${theatreId}` }, { type: 'Screen', id: screenId }],
    }),
    deleteScreen: builder.mutation({
      query: ({ theatreId, screenId }) => ({
        url: `/api/v1/theatres/${theatreId}/screens/${screenId}`,
        method: 'DELETE',
      }),
      invalidatesTags: (_result, _error, { theatreId, screenId }) => ['Screen', 'SeatLayout', 'Show', { type: 'Screen', id: `list-${theatreId}` }, { type: 'Screen', id: screenId }],
    }),
    createSeatLayout: builder.mutation({
      query: ({ theatreId, screenId, seatLayout }) => ({
        url: `/api/v1/theatres/${theatreId}/screens/${screenId}/seat_layouts`,
        method: 'POST',
        body: { seat_layout: seatLayout },
      }),
      invalidatesTags: (_result, _error, { screenId }) => ['SeatLayout', { type: 'SeatLayout', id: `screen-${screenId}` }],
    }),
    publishSeatLayout: builder.mutation({
      query: ({ theatreId, screenId, layoutId }) => ({
        url: `/api/v1/theatres/${theatreId}/screens/${screenId}/seat_layouts/${layoutId}/publish`,
        method: 'POST',
      }),
      invalidatesTags: (_result, _error, { screenId, layoutId }) => ['SeatLayout', { type: 'SeatLayout', id: `screen-${screenId}` }, { type: 'SeatLayout', id: layoutId }],
    }),
    archiveSeatLayout: builder.mutation({
      query: ({ theatreId, screenId, layoutId }) => ({
        url: `/api/v1/theatres/${theatreId}/screens/${screenId}/seat_layouts/${layoutId}/archive`,
        method: 'POST',
      }),
      invalidatesTags: (_result, _error, { screenId, layoutId }) => ['SeatLayout', { type: 'SeatLayout', id: `screen-${screenId}` }, { type: 'SeatLayout', id: layoutId }],
    }),
    syncSeatLayoutSections: builder.mutation({
      query: ({ theatreId, screenId, layoutId, sections }) => ({
        url: `/api/v1/theatres/${theatreId}/screens/${screenId}/seat_layouts/${layoutId}/sections`,
        method: 'PUT',
        body: { sections },
      }),
      invalidatesTags: (_result, _error, { layoutId }) => ['SeatLayout', { type: 'SeatLayout', id: layoutId }],
    }),
    syncSeatLayoutSeats: builder.mutation({
      query: ({ theatreId, screenId, layoutId, seats }) => ({
        url: `/api/v1/theatres/${theatreId}/screens/${screenId}/seat_layouts/${layoutId}/seats`,
        method: 'PUT',
        body: { seats },
      }),
      invalidatesTags: (_result, _error, { layoutId }) => ['SeatLayout', { type: 'SeatLayout', id: layoutId }],
    }),
    createShow: builder.mutation({
      query: ({ theatreId, screenId, show }) => ({
        url: `/api/v1/theatres/${theatreId}/screens/${screenId}/shows`,
        method: 'POST',
        body: { show },
      }),
      invalidatesTags: (_result, _error, { screenId }) => ['Show', { type: 'Show', id: `screen-${screenId}` }],
    }),
    updateShow: builder.mutation({
      query: ({ theatreId, screenId, showId, show }) => ({
        url: `/api/v1/theatres/${theatreId}/screens/${screenId}/shows/${showId}`,
        method: 'PATCH',
        body: { show },
      }),
      invalidatesTags: (_result, _error, { screenId, showId }) => ['Show', { type: 'Show', id: `screen-${screenId}` }, { type: 'Show', id: showId }],
    }),
    cancelShow: builder.mutation({
      query: ({ theatreId, screenId, showId }) => ({
        url: `/api/v1/theatres/${theatreId}/screens/${screenId}/shows/${showId}/cancel`,
        method: 'POST',
      }),
      invalidatesTags: (_result, _error, { screenId, showId }) => ['Show', { type: 'Show', id: `screen-${screenId}` }, { type: 'Show', id: showId }],
    }),
    createMovie: builder.mutation({
      query: (movie) => ({
        url: '/api/v1/movies',
        method: 'POST',
        body: { movie },
      }),
      invalidatesTags: ['Movie'],
    }),
    updateMovie: builder.mutation({
      query: ({ id, movie }) => ({
        url: `/api/v1/movies/${id}`,
        method: 'PATCH',
        body: { movie },
      }),
      invalidatesTags: (_result, _error, { id }) => ['Movie', { type: 'Movie', id }],
    }),
    deleteMovie: builder.mutation({
      query: (id) => ({
        url: `/api/v1/movies/${id}`,
        method: 'DELETE',
      }),
      invalidatesTags: ['Movie', 'Show'],
    }),
    createBooking: builder.mutation({
      query: (booking) => ({
        url: '/api/v1/bookings',
        method: 'POST',
        body: { booking },
      }),
      invalidatesTags: (_result, _error, booking) => ['Booking', { type: 'Show', id: `seats-${booking.show_id}` }],
    }),
    confirmBookingPayment: builder.mutation({
      query: (bookingId) => ({
        url: `/api/v1/bookings/${bookingId}/confirm_payment`,
        method: 'POST',
      }),
      invalidatesTags: (_result, _error, bookingId) => ['Booking', { type: 'Booking', id: bookingId }],
    }),
    cancelBooking: builder.mutation({
      query: (bookingId) => ({
        url: `/api/v1/bookings/${bookingId}/cancel`,
        method: 'POST',
      }),
      invalidatesTags: (_result, _error, bookingId) => ['Booking', { type: 'Booking', id: bookingId }, 'Show'],
    }),
    applyBookingCoupon: builder.mutation({
      query: ({ bookingId, couponCode }) => ({
        url: `/api/v1/bookings/${bookingId}/apply_coupon`,
        method: 'POST',
        body: { coupon_code: couponCode },
      }),
      invalidatesTags: (_result, _error, { bookingId }) => ['Booking', { type: 'Booking', id: bookingId }],
    }),
    createReferenceItem: builder.mutation({
      query: ({ apiPath, paramKey, payload }) => ({
        url: `/api/v1/${apiPath}`,
        method: 'POST',
        body: { [paramKey]: payload },
      }),
      invalidatesTags: ['City', 'Language', 'Format'],
    }),
    updateReferenceItem: builder.mutation({
      query: ({ apiPath, id, paramKey, payload }) => ({
        url: `/api/v1/${apiPath}/${id}`,
        method: 'PATCH',
        body: { [paramKey]: payload },
      }),
      invalidatesTags: ['City', 'Language', 'Format'],
    }),
    deleteReferenceItem: builder.mutation({
      query: ({ apiPath, id }) => ({
        url: `/api/v1/${apiPath}/${id}`,
        method: 'DELETE',
      }),
      invalidatesTags: ['City', 'Language', 'Format'],
    }),
  }),
})

export const {
  useApplyBookingCouponMutation,
  useArchiveSeatLayoutMutation,
  useCancelBookingMutation,
  useCancelShowMutation,
  useConfirmBookingPaymentMutation,
  useCreateBookingMutation,
  useCreateMovieMutation,
  useCreateReferenceItemMutation,
  useCreateScreenMutation,
  useCreateSeatLayoutMutation,
  useCreateShowMutation,
  useCreateTheatreMutation,
  useDeleteMovieMutation,
  useDeleteReferenceItemMutation,
  useDeleteScreenMutation,
  useDeleteTheatreMutation,
  useGetBookingQuery,
  useGetBookingsQuery,
  useGetCitiesQuery,
  useGetCouponsQuery,
  useGetFormatsQuery,
  useGetLanguagesQuery,
  useGetMoviesQuery,
  useGetMovieQuery,
  useGetMovieReviewsQuery,
  useGetReferenceItemsQuery,
  useGetScreenQuery,
  useGetScreensQuery,
  useGetScreenShowsQuery,
  useGetSeatLayoutQuery,
  useGetSeatLayoutsQuery,
  useGetShowQuery,
  useGetShowSeatsQuery,
  useGetShowsQuery,
  useGetTheatreQuery,
  useGetTheatresQuery,
  useGetVendorIncomeQuery,
  useGetVendorShowsSummaryQuery,
  useGetVendorSummariesQuery,
  useGetVendorsQuery,
  usePublishSeatLayoutMutation,
  useSyncSeatLayoutSectionsMutation,
  useSyncSeatLayoutSeatsMutation,
  useUpdateMovieMutation,
  useUpdateReferenceItemMutation,
  useUpdateScreenMutation,
  useUpdateShowMutation,
  useUpdateTheatreMutation,
} = apiSlice
