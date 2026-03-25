USERS {
    id: uuid PK
    name: string
    email: string unique
    password: string hashed
    phone: string
    role: enum('user', 'admin')
    is_active: bool
}

CITY {
    id: uuid PK
    name: string
    state: string
}

THEATRES {
    id: uuid PK
    owner_id: uuid FK → USERS.id
    name: string
    building_name: string
    street_address: string
    city_id: uuid FK → CITY.id
    pincode: string
}

SCREENS {
    id: uuid PK
    theatre_id: uuid FK → THEATRES.id
    name: string
    status: enum('active', 'inactive')
    total_rows: int
    total_columns: int
    total_seats: int
}

SCREEN_CAPABILITIES {
    id: uuid PK
    screen_id: uuid FK → SCREENS.id
    capability: enum('2D', '3D', '4DX', 'IMAX')
    unique(screen_id, capability)
}

SEATS {
    id: uuid PK
    screen_id: uuid FK → SCREENS.id
    type: enum('silver', 'gold', 'recliner', 'premium')
    row_label: string
    seat_number: int
    x_position: int
    y_position: int
    col_span: int default 1
    row_span: int default 1
    is_accessible: bool
    is_active: bool

UNIQUE (screen_id, x_position, y_position)
}

MOVIES {
    id: uuid PK
    title: string
    genre: string
    rating: enum('G', 'PG', 'PG-13', 'R', 'NC-17')
    description: text
    director: string
    running_time: int
    release_date: date
}

MOVIE_LANGUAGES {
    id: uuid PK
    movie_id: uuid FK → MOVIES.id
    language enum('English', 'Hindi', 'Tamil', 'Telugu', 'Marathi', 'Bengali', 'Kannada', 'Gujarati')
}

MOVIE_FORMATS {
    id: uuid PK
    movie_id: uuid FK → MOVIES.id
    format: enum('2D', '3D', '4DX', 'IMAX')
}

CAST_MEMBERS {
    id: uuid PK
    movie_id: uuid FK → MOVIES.id
    name: string
    role: enum('actor', 'actress', 'director', 'producer', 'writer')
    character_name: string nullable
}

SHOWS {
    id: uuid PK
    screen_id: uuid FK → SCREENS.id
    movie_id: uuid FK → MOVIES.id
    movie_language_id: uuid FK → MOVIE_LANGUAGES.id
    movie_format_id: uuid FK → MOVIE_FORMATS.id
    start_time: datetime
    end_time: datetime
    available_seats: int
    status: enum('scheduled', 'canceled', 'completed')
}

SHOW_PRICES {
    id: uuid PK
    show_id: uuid FK → SHOWS.id
    seat_type: enum('silver', 'gold', 'recliner', 'premium')
    base_price: decimal
    unique(show_id, seat_type)
}   

SHOW_SEATS {
    id: uuid PK
    show_id: uuid FK → SHOWS.id
    seat_id: uuid FK → SEATS.id
    status: enum('available', 'locked', 'booked')
    locked_by: uuid FK → USERS.id nullable
    locked_until: datetime nullable
    unique(show_id, seat_id)
}

BOOKINGS {
    id: uuid PK
    user_id: uuid FK → USERS.id
    show_id: uuid FK → SHOWS.id
    total_amount: decimal
    status: enum('pending', 'confirmed', 'partially-canceled', 'canceled')
    booking_time: datetime
}

TICKETS {
    id: uuid PK
    booking_id: uuid FK → BOOKINGS.id
    show_seat_id: uuid FK → SHOW_SEATS.id
    price: decimal
    status: enum('valid', 'canceled')
}

PAYMENTS {
    id: uuid PK
    booking_id: uuid FK → BOOKINGS.id
    transaction_id: string unique
    amount: decimal
    payment_time: datetime
    status: enum('pending', 'completed', 'failed')
    method: enum('credit_card', 'debit_card', 'net_banking', 'UPI', 'wallet')
    paid_at: datetime nullable
}

REVIEWS {
    id: uuid PK
    movie_id: uuid FK → MOVIES.id
    user_id: uuid FK → USERS.id
    description: text
    rating: int
    reviewed_on: date
    unique(movie_id, user_id)
}

COUPONS {
    id: uuid PK
    code: string unique
    discount_type: enum('percentage', 'fixed_amount')
    value: decimal
    valid_till: date
}