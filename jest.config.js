module.exports = {
  transform: {
    '^.+\\.js$': 'babel-jest',
  },
  testEnvironment: 'jsdom',

  setupFiles: ['<rootDir>/jest.setup.js'],
};
