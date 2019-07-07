///Maps the homie datatypes to their String representation according to the homie convention.
const Map<HomieDatatype, String> typeName = const <HomieDatatype, String>{
  HomieDatatype.typeColor: 'color',
  HomieDatatype.typeEnum: 'enum',
  HomieDatatype.typeFloat: 'float',
  HomieDatatype.typeInteger: 'integer',
  HomieDatatype.typeString: 'string',
  HomieDatatype.typeBoolean: 'boolean'
};

///A enum representing all datatypes defined in the homie convention.
enum HomieDatatype {
  typeString,
  typeInteger,
  typeFloat,
  typeBoolean,
  typeEnum,
  typeColor
}