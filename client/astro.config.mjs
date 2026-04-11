import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

export default defineConfig({
  integrations: [starlight({
    title: 'BookMyShow Clone API Docs',
    description: 'Reference docs for the Rails API powering the movie ticket booking platform.',
    defaultLocale: 'root',
    social: [
      { icon: 'github', label: 'Project Repository', href: 'https://github.com/madhavk-creator/bookmyshow-clone' },
    ],
    sidebar: [
      {
        label: 'Getting Started',
        items: [
          { label: 'Overview', link: '/' },
          { label: 'Authentication', slug: 'authentication' },
          { label: 'Booking Flow', slug: 'booking-flow' },
        ],
      },
      {
        label: 'Reference',
        items: [
          { label: 'Reference Data', slug: 'reference/reference-data' },
          { label: 'Movies', slug: 'reference/movies' },
          { label: 'Theatres And Screens', slug: 'reference/theatres-and-screens' },
          { label: 'Seat Layouts And Shows', slug: 'reference/seat-layouts-and-shows' },
          { label: 'Bookings And Coupons', slug: 'reference/bookings-and-coupons' },
        ],
      },
    ],
  })],
});
