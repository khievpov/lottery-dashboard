// pm2 process config used on the VPS. Loads DATABASE_URL and PORT from .env.
module.exports = {
  apps: [
    {
      name: 'lottery-dashboard',
      script: 'server.js',
      cwd: __dirname,
      node_args: '--env-file=.env',
      env: { NODE_ENV: 'production' },
      max_memory_restart: '300M',
    },
  ],
};
