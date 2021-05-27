@# Included from rosidl_typesupport_zenoh_cpp/resource/idl__type_support.cpp.em
@{
from rosidl_parser.definition import AbstractGenericString
from rosidl_parser.definition import AbstractNestedType
from rosidl_parser.definition import AbstractSequence
from rosidl_parser.definition import AbstractString
from rosidl_parser.definition import AbstractWString
from rosidl_parser.definition import Array
from rosidl_parser.definition import BasicType
from rosidl_parser.definition import BoundedSequence
from rosidl_parser.definition import NamespacedType

header_files = [
    'limits',
    'stdexcept',
    'string',
    'rosidl_typesupport_cpp/message_type_support.hpp',
    'rosidl_typesupport_zenoh_cpp/identifier.hpp',
    'rosidl_typesupport_zenoh_cpp/message_type_support.h',
    'rosidl_typesupport_zenoh_cpp/message_type_support_decl.hpp',
    'rosidl_typesupport_zenoh_cpp/wstring_conversion.hpp',
    'ucdr/microcdr.h',
]
}@
@[for header_file in header_files]@
@[    if header_file in include_directives]@
// already included above
// @
@[    else]@
@{include_directives.add(header_file)}@
@[    end if]@
@[    if '/' not in header_file]@
#include <@(header_file)>
@[    else]@
#include "@(header_file)"
@[    end if]@
@[end for]@


// forward declaration of message dependencies and their conversion functions
@[for member in message.structure.members]@
@{
type_ = member.type
if isinstance(type_, AbstractNestedType):
    type_ = type_.value_type
}@
@[  if isinstance(type_, NamespacedType)]@
@[    for ns in type_.namespaces]@
namespace @(ns)
{
@[    end for]@
namespace typesupport_zenoh_cpp
{
bool cdr_serialize(
  const @('::'.join(type_.namespaced_name())) &,
  eprosima::fastcdr::Cdr &);
bool cdr_deserialize(
  eprosima::fastcdr::Cdr &,
  @('::'.join(type_.namespaced_name())) &);
size_t get_serialized_size(
  const @('::'.join(type_.namespaced_name())) &,
  size_t current_alignment);
size_t
max_serialized_size_@(type_.name)(
  bool & full_bounded,
  size_t current_alignment);
bool cdr_serialize_ucdr(
  const @('::'.join(type_.namespaced_name())) &,
  ucdrBuffer *);
}  // namespace typesupport_zenoh_cpp
@[    for ns in reversed(type_.namespaces)]@
}  // namespace @(ns)
@[    end for]@

@[  end if]@
@[end for]@
@
@[  for ns in message.structure.namespaced_type.namespaces]@

namespace @(ns)
{
@[  end for]@

namespace typesupport_zenoh_cpp
{

bool
ROSIDL_TYPESUPPORT_ZENOH_CPP_PUBLIC_@(package_name)
cdr_serialize(
  const @('::'.join([package_name] + list(interface_path.parents[0].parts) + [message.structure.namespaced_type.name])) & ros_message,
  eprosima::fastcdr::Cdr & cdr)
{
@[for member in message.structure.members]@
  // Member: @(member.name)
@[  if isinstance(member.type, AbstractNestedType)]@
  {
@[    if isinstance(member.type, Array)]@
@[      if not isinstance(member.type.value_type, (NamespacedType, AbstractWString))]@
    cdr << ros_message.@(member.name);
@[      else]@
@[        if isinstance(member.type.value_type, AbstractWString)]@
    std::wstring wstr;
@[        end if]@
    for (size_t i = 0; i < @(member.type.size); i++) {
@[        if isinstance(member.type.value_type, NamespacedType)]@
      @('::'.join(member.type.value_type.namespaces))::typesupport_zenoh_cpp::cdr_serialize(
        ros_message.@(member.name)[i],
        cdr);
@[        else]@
      rosidl_typesupport_zenoh_cpp::u16string_to_wstring(ros_message.@(member.name)[i], wstr);
      cdr << wstr;
@[        end if]@
    }
@[      end if]@
@[    else]@
@[      if isinstance(member.type, BoundedSequence) or isinstance(member.type.value_type, (NamespacedType, AbstractWString))]@
    size_t size = ros_message.@(member.name).size();
@[        if isinstance(member.type, BoundedSequence)]@
    if (size > @(member.type.maximum_size)) {
      throw std::runtime_error("array size exceeds upper bound");
    }
@[        end if]@
@[      end if]@
@[      if not isinstance(member.type.value_type, (NamespacedType, AbstractWString)) and not isinstance(member.type, BoundedSequence)]@
    cdr << ros_message.@(member.name);
@[      else]@
    cdr << static_cast<uint32_t>(size);
@[        if isinstance(member.type.value_type, AbstractWString)]@
    std::wstring wstr;
@[        end if]@
    for (size_t i = 0; i < size; i++) {
@[        if isinstance(member.type.value_type, BasicType) and member.type.value_type.typename == 'boolean']@
      cdr << (ros_message.@(member.name)[i] ? true : false);
@[        elif isinstance(member.type.value_type, BasicType) and member.type.value_type.typename == 'wchar']@
      cdr << static_cast<wchar_t>(ros_message.@(member.name)[i]);
@[        elif isinstance(member.type.value_type, AbstractWString)]@
      rosidl_typesupport_zenoh_cpp::u16string_to_wstring(ros_message.@(member.name)[i], wstr);
      cdr << wstr;
@[        elif not isinstance(member.type.value_type, NamespacedType)]@
      cdr << ros_message.@(member.name)[i];
@[        else]@
      @('::'.join(member.type.value_type.namespaces))::typesupport_zenoh_cpp::cdr_serialize(
        ros_message.@(member.name)[i],
        cdr);
@[        end if]@
    }
@[      end if]@
@[    end if]@
  }
@[  elif isinstance(member.type, BasicType) and member.type.typename == 'boolean']@
  cdr << (ros_message.@(member.name) ? true : false);
@[  elif isinstance(member.type, BasicType) and member.type.typename == 'wchar']@
  cdr << static_cast<wchar_t>(ros_message.@(member.name));
@[  elif isinstance(member.type, AbstractWString)]@
  {
    std::wstring wstr;
    rosidl_typesupport_zenoh_cpp::u16string_to_wstring(ros_message.@(member.name), wstr);
    cdr << wstr;
  }
@[  elif not isinstance(member.type, NamespacedType)]@
  cdr << ros_message.@(member.name);
@[  else]@
  @('::'.join(member.type.namespaces))::typesupport_zenoh_cpp::cdr_serialize(
    ros_message.@(member.name),
    cdr);
@[  end if]@
@[end for]@
  return true;
}

bool
ROSIDL_TYPESUPPORT_ZENOH_CPP_PUBLIC_@(package_name)
cdr_serialize_ucdr(
  const @('::'.join([package_name] + list(interface_path.parents[0].parts) + [message.structure.namespaced_type.name])) & ros_message,
  ucdrBuffer * writer)
{
@[for member in message.structure.members]@
  // Member: @(member.name)
@[  if isinstance(member.type, AbstractNestedType)]@
  {
@[    if isinstance(member.type, Array)]@

    size_t size = @(member.type.size);
    auto array_ptr = ros_message.@(member.name).data();

@[      if not isinstance(member.type.value_type, (NamespacedType, AbstractWString))]@


@[  if isinstance(member.type.value_type, BasicType) and member.type.value_type.typename == 'boolean']@
  ucdr_serialize_array_bool(writer, ros_message.@(member.name).data(), @(member.type.size));
@[  elif isinstance(member.type.value_type, BasicType) and member.type.value_type.typename == 'wchar']@
  ucdr_serialize_array_wchar(writer, ros_message.@(member.name).data(), @(member.type.size));
@[  elif isinstance(member.type.value_type, BasicType) and member.type.value_type.typename == 'octet']@
  ucdr_serialize_array_uint8_t(writer, ros_message.@(member.name).data(), @(member.type.size));
@[  elif isinstance(member.type.value_type, BasicType) and member.type.value_type.typename == 'int8']@
  ucdr_serialize_array_int8_t(writer, ros_message.@(member.name).data(), @(member.type.size));
@[  elif isinstance(member.type.value_type, BasicType) and member.type.value_type.typename == 'uint8']@
  ucdr_serialize_array_uint8_t(writer, ros_message.@(member.name).data(), @(member.type.size));
@[  elif isinstance(member.type.value_type, BasicType) and member.type.value_type.typename == 'int16']@
  ucdr_serialize_array_int16_t(writer, ros_message.@(member.name).data(), @(member.type.size));
@[  elif isinstance(member.type.value_type, BasicType) and member.type.value_type.typename == 'uint16']@
  ucdr_serialize_array_uint16_t(writer, ros_message.@(member.name).data(), @(member.type.size));
@[  elif isinstance(member.type.value_type, BasicType) and member.type.value_type.typename == 'int32']@
  ucdr_serialize_array_int32_t(writer, ros_message.@(member.name).data(), @(member.type.size));
@[  elif isinstance(member.type.value_type, BasicType) and member.type.value_type.typename == 'uint32']@
  ucdr_serialize_array_uint32_t(writer, ros_message.@(member.name).data(), @(member.type.size));
@[  elif isinstance(member.type.value_type, BasicType) and member.type.value_type.typename == 'int64']@
  ucdr_serialize_array_int64_t(writer, ros_message.@(member.name).data(), @(member.type.size));
@[  elif isinstance(member.type.value_type, BasicType) and member.type.value_type.typename == 'uint64']@
  ucdr_serialize_array_uint64_t(writer, ros_message.@(member.name).data(), @(member.type.size));
@[  elif isinstance(member.type.value_type, BasicType) and member.type.value_type.typename == 'char']@
  ucdr_serialize_array_char(writer, ros_message.@(member.name).data(), @(member.type.size));
@[  elif isinstance(member.type.value_type, BasicType) and member.type.value_type.typename == 'wchar']@
  ucdr_serialize_array_wchar(writer, ros_message.@(member.name).data(), @(member.type.size));
@[  elif isinstance(member.type.value_type, BasicType) and member.type.value_type.typename == 'float']@
  ucdr_serialize_array_float(writer, ros_message.@(member.name).data(), @(member.type.size));
@[  elif isinstance(member.type.value_type, BasicType) and member.type.value_type.typename == 'double']@
  ucdr_serialize_array_double(writer, ros_message.@(member.name).data(), @(member.type.size));
@[    elif isinstance(member.type.value_type, AbstractString)]@
    for (size_t i = 0; i < @(member.type.size); ++i) {
      ucdr_serialize_array_char(writer, ros_message.@(member.name)[i].data(), ros_message.@(member.name)[i].size());
    }
@[  elif isinstance(member.type.value_type, BasicType)]@
#error Unknown basic type @(member.type) for member @(member.name)
@[  else]@
#error Serialization not supported for member @(member.name) @(member.type)
@[  end if]@

@[      else]@
@[        if isinstance(member.type.value_type, AbstractWString)]@
    // TODO(esteve): add support for wstring
#error "Wide strings not supported"
@[        end if]@
    for (size_t i = 0; i < @(member.type.size); i++) {
@[        if isinstance(member.type.value_type, NamespacedType)]@
      @('::'.join(member.type.value_type.namespaces))::typesupport_zenoh_cpp::cdr_serialize_ucdr(
        ros_message.@(member.name)[i],
        writer);
@[        else]@
      // TODO(esteve): add support for wstring
#error "Wide strings not supported"
@[        end if]@
    }
@[      end if]@
@[    else]@
@[      if isinstance(member.type, BoundedSequence) or isinstance(member.type.value_type, (NamespacedType, AbstractWString))]@
    size_t size = ros_message.@(member.name).size();
@[        if isinstance(member.type, BoundedSequence)]@
    if (size > @(member.type.maximum_size)) {
      throw std::runtime_error("array size exceeds upper bound");
    }
@[        end if]@
@[      end if]@
@[      if not isinstance(member.type.value_type, (NamespacedType, AbstractWString)) and not isinstance(member.type, BoundedSequence)]@


@[  if isinstance(member.type, BasicType) and member.type.typename == 'octet']@
  ucdr_serialize_uint8_t(writer, ros_message.@(member.name));
@[  elif isinstance(member.type, BasicType) and member.type.typename == 'int8']@
  ucdr_serialize_int8_t(writer, ros_message.@(member.name));
@[  elif isinstance(member.type, BasicType) and member.type.typename == 'uint8']@
  ucdr_serialize_uint8_t(writer, ros_message.@(member.name));
@[  elif isinstance(member.type, BasicType) and member.type.typename == 'int16']@
  ucdr_serialize_int16_t(writer, ros_message.@(member.name));
@[  elif isinstance(member.type, BasicType) and member.type.typename == 'uint16']@
  ucdr_serialize_uint16_t(writer, ros_message.@(member.name));
@[  elif isinstance(member.type, BasicType) and member.type.typename == 'int32']@
  ucdr_serialize_int32_t(writer, ros_message.@(member.name));
@[  elif isinstance(member.type, BasicType) and member.type.typename == 'uint32']@
  ucdr_serialize_uint32_t(writer, ros_message.@(member.name));
@[  elif isinstance(member.type, BasicType) and member.type.typename == 'int64']@
  ucdr_serialize_int64_t(writer, ros_message.@(member.name));
@[  elif isinstance(member.type, BasicType) and member.type.typename == 'uint64']@
  ucdr_serialize_uint64_t(writer, ros_message.@(member.name));
@[  elif isinstance(member.type, BasicType) and member.type.typename == 'char']@
  ucdr_serialize_char(writer, ros_message.@(member.name));
@[  elif isinstance(member.type, BasicType) and member.type.typename == 'wchar']@
  ucdr_serialize_wchar(writer, ros_message.@(member.name));
@[  elif isinstance(member.type, BasicType) and member.type.typename == 'float']@
  ucdr_serialize_float(writer, ros_message.@(member.name));
@[  elif isinstance(member.type, BasicType) and member.type.typename == 'double']@
  ucdr_serialize_double(writer, ros_message.@(member.name));
@[  elif isinstance(member.type, BasicType)]@
#error Unknown basic type @(member.type) for member @(member.name)
@[  end if]@

@[      else]@
    ucdr_serialize_uint32_t(writer, size);
@[        if isinstance(member.type.value_type, AbstractWString)]@
    std::wstring wstr;
@[        end if]@
    for (size_t i = 0; i < size; i++) {
@[        if isinstance(member.type.value_type, BasicType) and member.type.value_type.typename == 'boolean']@
      ucdr_serialize_bool(writer, ros_message.@(member.name)[i] ? true : false);
@[        elif isinstance(member.type.value_type, BasicType) and member.type.value_type.typename == 'wchar']@
      ucdr_serialize_wchar(writer, ros_message.@(member.name)[i]);
@[        elif isinstance(member.type.value_type, BasicType) and member.type.value_type.typename == 'octet']@
      ucdr_serialize_uint8_t(writer, ros_message.@(member.name)[i]);
@[        elif isinstance(member.type.value_type, BasicType) and member.type.value_type.typename == 'int8']@
      ucdr_serialize_int8_t(writer, ros_message.@(member.name)[i]);
@[        elif isinstance(member.type.value_type, BasicType) and member.type.value_type.typename == 'uint8']@
      ucdr_serialize_uint8_t(writer, ros_message.@(member.name)[i]);
@[        elif isinstance(member.type.value_type, BasicType) and member.type.value_type.typename == 'int16']@
      ucdr_serialize_int16_t(writer, ros_message.@(member.name)[i]);
@[        elif isinstance(member.type.value_type, BasicType) and member.type.value_type.typename == 'uint16']@
      ucdr_serialize_uint16_t(writer, ros_message.@(member.name)[i]);
@[        elif isinstance(member.type.value_type, BasicType) and member.type.value_type.typename == 'int32']@
      ucdr_serialize_int32_t(writer, ros_message.@(member.name)[i]);
@[        elif isinstance(member.type.value_type, BasicType) and member.type.value_type.typename == 'uint32']@
      ucdr_serialize_uint32_t(writer, ros_message.@(member.name)[i]);
@[        elif isinstance(member.type.value_type, BasicType) and member.type.value_type.typename == 'int64']@
      ucdr_serialize_int64_t(writer, ros_message.@(member.name)[i]);
@[        elif isinstance(member.type.value_type, BasicType) and member.type.value_type.typename == 'uint64']@
      ucdr_serialize_uint64_t(writer, ros_message.@(member.name)[i]);
@[        elif isinstance(member.type.value_type, BasicType) and member.type.value_type.typename == 'char']@
      ucdr_serialize_char(writer, ros_message.@(member.name)[i]);
@[        elif isinstance(member.type.value_type, BasicType) and member.type.value_type.typename == 'wchar']@
      ucdr_serialize_wchar(writer, ros_message.@(member.name)[i]);
@[        elif isinstance(member.type.value_type, BasicType) and member.type.value_type.typename == 'float']@
      ucdr_serialize_float(writer, ros_message.@(member.name)[i]);
@[        elif isinstance(member.type.value_type, BasicType) and member.type.value_type.typename == 'double']@
      ucdr_serialize_double(writer, ros_message.@(member.name)[i]);
@[        elif isinstance(member.type.value_type, AbstractWString)]@
    // TODO(esteve): add support for wstring
#error "Arrays of wide strings not supported"
@[        elif not isinstance(member.type.value_type, NamespacedType)]@
      ucdr_serialize_array_char(writer, ros_message.@(member.name)[i].data(), ros_message.@(member.name)[i].size());
@[        else]@
      @('::'.join(member.type.value_type.namespaces))::typesupport_zenoh_cpp::cdr_serialize_ucdr(
        ros_message.@(member.name)[i],
        writer);
@[        end if]@
    }
@[      end if]@
@[    end if]@
  }
@[  elif isinstance(member.type, BasicType) and member.type.typename == 'boolean']@
  ucdr_serialize_bool(writer, (ros_message.@(member.name) ? true : false));
@[  elif isinstance(member.type, BasicType) and member.type.typename == 'wchar']@
  ucdr_serialize_wchar(writer, ros_message.@(member.name));
@[  elif isinstance(member.type, BasicType) and member.type.typename == 'octet']@
  ucdr_serialize_uint8_t(writer, ros_message.@(member.name));
@[  elif isinstance(member.type, BasicType) and member.type.typename == 'int8']@
  ucdr_serialize_int8_t(writer, ros_message.@(member.name));
@[  elif isinstance(member.type, BasicType) and member.type.typename == 'uint8']@
  ucdr_serialize_uint8_t(writer, ros_message.@(member.name));
@[  elif isinstance(member.type, BasicType) and member.type.typename == 'int16']@
  ucdr_serialize_int16_t(writer, ros_message.@(member.name));
@[  elif isinstance(member.type, BasicType) and member.type.typename == 'uint16']@
  ucdr_serialize_uint16_t(writer, ros_message.@(member.name));
@[  elif isinstance(member.type, BasicType) and member.type.typename == 'int32']@
  ucdr_serialize_int32_t(writer, ros_message.@(member.name));
@[  elif isinstance(member.type, BasicType) and member.type.typename == 'uint32']@
  ucdr_serialize_uint32_t(writer, ros_message.@(member.name));
@[  elif isinstance(member.type, BasicType) and member.type.typename == 'int64']@
  ucdr_serialize_int64_t(writer, ros_message.@(member.name));
@[  elif isinstance(member.type, BasicType) and member.type.typename == 'uint64']@
  ucdr_serialize_uint64_t(writer, ros_message.@(member.name));
@[  elif isinstance(member.type, BasicType) and member.type.typename == 'char']@
  ucdr_serialize_char(writer, ros_message.@(member.name));
@[  elif isinstance(member.type, BasicType) and member.type.typename == 'wchar']@
  ucdr_serialize_wchar(writer, ros_message.@(member.name));
@[  elif isinstance(member.type, BasicType) and member.type.typename == 'float']@
  ucdr_serialize_float(writer, ros_message.@(member.name));
@[  elif isinstance(member.type, BasicType) and member.type.typename == 'double']@
  ucdr_serialize_double(writer, ros_message.@(member.name));
@[  elif isinstance(member.type, AbstractWString)]@
  {
    std::wstring wstr;
    rosidl_typesupport_zenoh_cpp::u16string_to_wstring(ros_message.@(member.name), wstr);
// TODO(esteve): add support for wide strings
#error Wide string not supported yet
  }
@[  elif not isinstance(member.type, NamespacedType)]@
#warning Unknown basic type @(member.type) for member @(member.name)
@[  else]@
  @('::'.join(member.type.namespaces))::typesupport_zenoh_cpp::cdr_serialize_ucdr(
    ros_message.@(member.name),
    writer);
@[  end if]@
@[end for]@
  return true;
}

bool
ROSIDL_TYPESUPPORT_ZENOH_CPP_PUBLIC_@(package_name)
cdr_deserialize(
  eprosima::fastcdr::Cdr & cdr,
  @('::'.join([package_name] + list(interface_path.parents[0].parts) + [message.structure.namespaced_type.name])) & ros_message)
{
@[for member in message.structure.members]@
  // Member: @(member.name)
@[  if isinstance(member.type, AbstractNestedType)]@
  {
@[    if isinstance(member.type, Array)]@
@[      if not isinstance(member.type.value_type, (NamespacedType, AbstractWString))]@
    cdr >> ros_message.@(member.name);
@[      else]@
@[        if isinstance(member.type.value_type, AbstractWString)]@
    std::wstring wstr;
@[        end if]@
    for (size_t i = 0; i < @(member.type.size); i++) {
@[        if isinstance(member.type.value_type, NamespacedType)]@
      @('::'.join(member.type.value_type.namespaces))::typesupport_zenoh_cpp::cdr_deserialize(
        cdr,
        ros_message.@(member.name)[i]);
@[        else]@
      cdr >> wstr;
      bool succeeded = rosidl_typesupport_zenoh_cpp::wstring_to_u16string(wstr, ros_message.@(member.name)[i]);
      if (!succeeded) {
        fprintf(stderr, "failed to create wstring from u16string\n");
        return false;
      }
@[        end if]@
    }
@[      end if]@
@[    else]@
@[      if not isinstance(member.type.value_type, (NamespacedType, AbstractWString)) and not isinstance(member.type, BoundedSequence)]@
    cdr >> ros_message.@(member.name);
@[      else]@
    uint32_t cdrSize;
    cdr >> cdrSize;
    size_t size = static_cast<size_t>(cdrSize);
    ros_message.@(member.name).resize(size);
@[        if isinstance(member.type.value_type, AbstractWString)]@
    std::wstring wstr;
@[        end if]@
    for (size_t i = 0; i < size; i++) {
@[        if isinstance(member.type.value_type, BasicType) and member.type.value_type.typename == 'boolean']@
      uint8_t tmp;
      cdr >> tmp;
      ros_message.@(member.name)[i] = tmp ? true : false;
@[        elif isinstance(member.type.value_type, BasicType) and member.type.value_type.typename == 'wchar']@
      wchar_t tmp;
      cdr >> tmp;
      ros_message.@(member.name)[i] = static_cast<char16_t>(tmp);
@[        elif isinstance(member.type.value_type, AbstractWString)]@
      cdr >> wstr;
      bool succeeded = rosidl_typesupport_zenoh_cpp::wstring_to_u16string(wstr, ros_message.@(member.name)[i]);
      if (!succeeded) {
        fprintf(stderr, "failed to create wstring from u16string\n");
        return false;
      }
@[        elif not isinstance(member.type.value_type, NamespacedType)]@
      cdr >> ros_message.@(member.name)[i];
@[        else]@
      @('::'.join(member.type.value_type.namespaces))::typesupport_zenoh_cpp::cdr_deserialize(
        cdr, ros_message.@(member.name)[i]);
@[        end if]@
    }
@[      end if]@
@[    end if]@
  }
@[  elif isinstance(member.type, BasicType) and member.type.typename == 'boolean']@
  {
    uint8_t tmp;
    cdr >> tmp;
    ros_message.@(member.name) = tmp ? true : false;
  }
@[  elif isinstance(member.type, BasicType) and member.type.typename == 'wchar']@
  {
    wchar_t tmp;
    cdr >> tmp;
    ros_message.@(member.name) = static_cast<char16_t>(tmp);
  }
@[  elif isinstance(member.type, AbstractWString)]@
  {
    std::wstring wstr;
    cdr >> wstr;
    bool succeeded = rosidl_typesupport_zenoh_cpp::wstring_to_u16string(wstr, ros_message.@(member.name));
    if (!succeeded) {
      fprintf(stderr, "failed to create wstring from u16string\n");
      return false;
    }
  }
@[  elif not isinstance(member.type, NamespacedType)]@
  cdr >> ros_message.@(member.name);
@[  else]@
  @('::'.join(member.type.namespaces))::typesupport_zenoh_cpp::cdr_deserialize(
    cdr, ros_message.@(member.name));
@[  end if]@

@[end for]@
  return true;
}

size_t
ROSIDL_TYPESUPPORT_ZENOH_CPP_PUBLIC_@(package_name)
get_serialized_size(
  const @('::'.join([package_name] + list(interface_path.parents[0].parts) + [message.structure.namespaced_type.name])) & ros_message,
  size_t current_alignment)
{
  size_t initial_alignment = current_alignment;

  const size_t padding = 4;
  const size_t wchar_size = 4;
  (void)padding;
  (void)wchar_size;

@[for member in message.structure.members]@
  // Member: @(member.name)
@[  if isinstance(member.type, AbstractNestedType)]@
  {
@[    if isinstance(member.type, Array)]@
    size_t array_size = @(member.type.size);
@[    else]@
    size_t array_size = ros_message.@(member.name).size();
@[      if isinstance(member.type, BoundedSequence)]@
    if (array_size > @(member.type.maximum_size)) {
      throw std::runtime_error("array size exceeds upper bound");
    }
@[      end if]@

    current_alignment += padding +
      eprosima::fastcdr::Cdr::alignment(current_alignment, padding);
@[    end if]@
@[    if isinstance(member.type.value_type, AbstractGenericString)]@
    for (size_t index = 0; index < array_size; ++index) {
      current_alignment += padding +
        eprosima::fastcdr::Cdr::alignment(current_alignment, padding) +
@[      if isinstance(member.type.value_type, AbstractWString)]@
        wchar_size *
@[      end if]@
        (ros_message.@(member.name)[index].size() + 1);
    }
@[    elif isinstance(member.type.value_type, BasicType)]@
    size_t item_size = sizeof(ros_message.@(member.name)[0]);
    current_alignment += array_size * item_size +
      eprosima::fastcdr::Cdr::alignment(current_alignment, item_size);
@[    else]
    for (size_t index = 0; index < array_size; ++index) {
      current_alignment +=
        @('::'.join(member.type.value_type.namespaces))::typesupport_zenoh_cpp::get_serialized_size(
        ros_message.@(member.name)[index], current_alignment);
    }
@[    end if]@
  }
@[  else]@
@[    if isinstance(member.type, AbstractGenericString)]@
  current_alignment += padding +
    eprosima::fastcdr::Cdr::alignment(current_alignment, padding) +
@[      if isinstance(member.type, AbstractWString)]@
    wchar_size *
@[      end if]@
    (ros_message.@(member.name).size() + 1);
@[    elif isinstance(member.type, BasicType)]@
  {
    size_t item_size = sizeof(ros_message.@(member.name));
    current_alignment += item_size +
      eprosima::fastcdr::Cdr::alignment(current_alignment, item_size);
  }
@[    else]
  current_alignment +=
    @('::'.join(member.type.namespaces))::typesupport_zenoh_cpp::get_serialized_size(
    ros_message.@(member.name), current_alignment);
@[    end if]@
@[  end if]@
@[end for]@

  return current_alignment - initial_alignment;
}

size_t
ROSIDL_TYPESUPPORT_ZENOH_CPP_PUBLIC_@(package_name)
max_serialized_size_@(message.structure.namespaced_type.name)(
  bool & full_bounded,
  size_t current_alignment)
{
  size_t initial_alignment = current_alignment;

  const size_t padding = 4;
  const size_t wchar_size = 4;
  (void)padding;
  (void)wchar_size;
  (void)full_bounded;

@[for member in message.structure.members]@

  // Member: @(member.name)
  {
@[  if isinstance(member.type, AbstractNestedType)]@
@[    if isinstance(member.type, Array)]@
    size_t array_size = @(member.type.size);
@[    elif isinstance(member.type, BoundedSequence)]@
    size_t array_size = @(member.type.maximum_size);
@[    else]@
    size_t array_size = 0;
@[    end if]@
@[    if isinstance(member.type, AbstractSequence)]@
    full_bounded = false;
    current_alignment += padding +
      eprosima::fastcdr::Cdr::alignment(current_alignment, padding);
@[    end if]@
@[  else]@
    size_t array_size = 1;
@[  end if]@

@{
type_ = member.type
if isinstance(type_, AbstractNestedType):
    type_ = type_.value_type
}@
@[  if isinstance(type_, AbstractGenericString)]@
    full_bounded = false;
    for (size_t index = 0; index < array_size; ++index) {
      current_alignment += padding +
        eprosima::fastcdr::Cdr::alignment(current_alignment, padding) +
@[    if type_.has_maximum_size()]@
@[      if isinstance(type_, AbstractWString)]@
        wchar_size *
@[      end if]@
        @(type_.maximum_size) +
@[    end if]@
@[    if isinstance(type_, AbstractWString)]@
        wchar_size *
@[    end if]@
        1;
    }
@[  elif isinstance(type_, BasicType)]@
@[    if type_.typename in ('boolean', 'octet', 'char', 'uint8', 'int8')]@
    current_alignment += array_size * sizeof(uint8_t);
@[    elif type_.typename in ('wchar', 'int16', 'uint16')]@
    current_alignment += array_size * sizeof(uint16_t) +
      eprosima::fastcdr::Cdr::alignment(current_alignment, sizeof(uint16_t));
@[    elif type_.typename in ('int32', 'uint32', 'float')]@
    current_alignment += array_size * sizeof(uint32_t) +
      eprosima::fastcdr::Cdr::alignment(current_alignment, sizeof(uint32_t));
@[    elif type_.typename in ('int64', 'uint64', 'double')]@
    current_alignment += array_size * sizeof(uint64_t) +
      eprosima::fastcdr::Cdr::alignment(current_alignment, sizeof(uint64_t));
@[    elif type_.typename == 'long double']@
    current_alignment += array_size * sizeof(long double) +
      eprosima::fastcdr::Cdr::alignment(current_alignment, sizeof(long double));
@[    end if]@
@[  else]
    for (size_t index = 0; index < array_size; ++index) {
      current_alignment +=
        @('::'.join(type_.namespaces))::typesupport_zenoh_cpp::max_serialized_size_@(type_.name)(
        full_bounded, current_alignment);
    }
@[  end if]@
  }
@[end for]@

  return current_alignment - initial_alignment;
}

static bool _@(message.structure.namespaced_type.name)__cdr_serialize(
  const void * untyped_ros_message,
  eprosima::fastcdr::Cdr & cdr)
{
  auto typed_message =
    static_cast<const @('::'.join([package_name] + list(interface_path.parents[0].parts) + [message.structure.namespaced_type.name])) *>(
    untyped_ros_message);
  return cdr_serialize(*typed_message, cdr);
}

static bool _@(message.structure.namespaced_type.name)__cdr_serialize_ucdr(
  const void * untyped_ros_message,
  ucdrBuffer * writer)
{
  auto typed_message =
    static_cast<const @('::'.join([package_name] + list(interface_path.parents[0].parts) + [message.structure.namespaced_type.name])) *>(
    untyped_ros_message);
  return cdr_serialize_ucdr(*typed_message, writer);
}

static bool _@(message.structure.namespaced_type.name)__cdr_deserialize(
  eprosima::fastcdr::Cdr & cdr,
  void * untyped_ros_message)
{
  auto typed_message =
    static_cast<@('::'.join([package_name] + list(interface_path.parents[0].parts) + [message.structure.namespaced_type.name])) *>(
    untyped_ros_message);
  return cdr_deserialize(cdr, *typed_message);
}

static uint32_t _@(message.structure.namespaced_type.name)__get_serialized_size(
  const void * untyped_ros_message)
{
  auto typed_message =
    static_cast<const @('::'.join([package_name] + list(interface_path.parents[0].parts) + [message.structure.namespaced_type.name])) *>(
    untyped_ros_message);
  return static_cast<uint32_t>(get_serialized_size(*typed_message, 0));
}

static size_t _@(message.structure.namespaced_type.name)__max_serialized_size(bool & full_bounded)
{
  return max_serialized_size_@(message.structure.namespaced_type.name)(full_bounded, 0);
}

static message_type_support_callbacks_t _@(message.structure.namespaced_type.name)__callbacks = {
  "@('::'.join([package_name] + list(interface_path.parents[0].parts)))",
  "@(message.structure.namespaced_type.name)",
  _@(message.structure.namespaced_type.name)__cdr_serialize,
  _@(message.structure.namespaced_type.name)__cdr_serialize_ucdr,
  _@(message.structure.namespaced_type.name)__cdr_deserialize,
  _@(message.structure.namespaced_type.name)__get_serialized_size,
  _@(message.structure.namespaced_type.name)__max_serialized_size
};

static rosidl_message_type_support_t _@(message.structure.namespaced_type.name)__handle = {
  rosidl_typesupport_zenoh_cpp::typesupport_identifier,
  &_@(message.structure.namespaced_type.name)__callbacks,
  get_message_typesupport_handle_function,
};

}  // namespace typesupport_zenoh_cpp
@[  for ns in reversed(message.structure.namespaced_type.namespaces)]@

}  // namespace @(ns)
@[  end for]@

namespace rosidl_typesupport_zenoh_cpp
{

template<>
ROSIDL_TYPESUPPORT_ZENOH_CPP_EXPORT_@(package_name)
const rosidl_message_type_support_t *
get_message_type_support_handle<@('::'.join([package_name] + list(interface_path.parents[0].parts) + [message.structure.namespaced_type.name]))>()
{
  return &@('::'.join([package_name] + list(interface_path.parents[0].parts)))::typesupport_zenoh_cpp::_@(message.structure.namespaced_type.name)__handle;
}

}  // namespace rosidl_typesupport_zenoh_cpp

#ifdef __cplusplus
extern "C"
{
#endif

const rosidl_message_type_support_t *
ROSIDL_TYPESUPPORT_INTERFACE__MESSAGE_SYMBOL_NAME(rosidl_typesupport_zenoh_cpp, @(', '.join([package_name] + list(interface_path.parents[0].parts) + [message.structure.namespaced_type.name])))() {
  return &@('::'.join([package_name] + list(interface_path.parents[0].parts)))::typesupport_zenoh_cpp::_@(message.structure.namespaced_type.name)__handle;
}

#ifdef __cplusplus
}
#endif
