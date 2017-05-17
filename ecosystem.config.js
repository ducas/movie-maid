module.exports = {
  apps : [
    {
      name      : 'Move TV',
      script    : 'app.js',
      args      : ['-p', '-s', '/mnt/library/Downloads/complete/TV', '-d', '/mnt/library/TV']
    },

    {
      name      : 'Move Movies',
      script    : 'app.js',
      args      : ['-s', '/mnt/library/Downloads/complete/Movies', '-d', '/mnt/library/Movies']
    }
  ],

  deploy : {
    production : {
      user : 'pi',
      host : '10.1.1.15',
      ref  : 'origin/master',
      repo : 'git@github.com:ducas/movie-maid.git',
      path : '/home/pi/movie-maid-deploy',
      'post-deploy' : 'npm install && pm2 reload ecosystem.config.js --env production'
    }
  }
};
