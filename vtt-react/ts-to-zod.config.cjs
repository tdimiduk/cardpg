/**
 * ts-to-zod configuration.
 *
 * @type {import("ts-to-zod").TsToZodConfig}
 */
module.exports = {
  input: 'src/generated/types.ts',
  output: 'src/generated/types.zod.ts',
};
