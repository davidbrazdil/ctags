#!/bin/sh
TMP_NAMES=`mktemp`
TMP_TAGS=`mktemp`
OUTPUT="$1"

ctags -x --c-kinds=f -f *.c | grep "^Java_\|^JNI_" | cut -d' ' -f 1 > "$TMP_NAMES"
ctags --c-kinds=f --fields=+ST -f "$TMP_TAGS" *.c > /dev/null

rm -f "$OUTPUT"

cat <<EOF >> "$OUTPUT"
#include <jni.h>

#define UNUSED	__attribute__ ((__unused__))

EOF

while read FN_NAME; do
	FN_SIGNATURE=`cat "$TMP_TAGS" | grep "^$FN_NAME	" | cut -f 5 | sed 's/signature://'`
	FN_RETURNTYPE=`cat "$TMP_TAGS" | grep "^$FN_NAME	" | cut -f 6 | sed 's/returntype://' | sed 's/JNIEXPORT//' | sed 's/JNICALL//'`
	echo "extern $FN_RETURNTYPE $FN_NAME $FN_SIGNATURE;" >> "$OUTPUT"
done < "$TMP_NAMES"

cat <<EOF >> "$OUTPUT"

typedef struct method_entry {
	char *name;
	void *func;
} methodEntry;

methodEntry cherijni_MethodList[] = {
EOF

while read FN_NAME; do
	echo "	{ \"$FN_NAME\", &$FN_NAME }," >> "$OUTPUT"
done < "$TMP_NAMES"

cat <<EOF >> "$OUTPUT"
	{NULL, NULL}
};
EOF

rm -f "$TMP_NAMES" "$TMP_TAGS"
