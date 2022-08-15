module.exports = {
  setupFilesAfterEnv: ['./client/src/setupTests.ts'],
  moduleDirectories: ['client/src', 'node_modules'],
  moduleNameMapper: {
    '\\.(jpg|jpeg|png|gif)$': '<rootDir>/client/src/assetsTransformer.js',
    '^~/(.*)$': '<rootDir>/client/src/$1',
    'react-markdown': '<rootDir>/node_modules/react-markdown/react-markdown.min.js',
  },
  transform: {
    '^.+\\.ts?$': 'ts-jest',
    '^.+\\.js?$': 'babel-jest',
  },
  transformIgnorePatterns: ['node_modules/(?!(react-markdown|remark-gfm)/)'],
  collectCoverageFrom: ['**/*.{ts,tsx}', '!**/node_modules/**'],
};
