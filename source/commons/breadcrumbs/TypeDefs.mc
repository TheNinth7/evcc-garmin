import Toybox.Lang;

typedef ArrayOfBreadCrumbs as Array<EvccBreadCrumb?>;

// Crumb, serialized for storage
// ATTENTION: there is a bug in the compiler typecheck that causes stack overflow
// with recursive tuples under some circumstances. For now this code circumvents
// these (not fully understood) circumstances, but changes may trigger the bug
// again.
// https://forums.garmin.com/developer/connect-iq/i/bug-reports/compiler-crash-with-recursive-typedef-tuple
// https://forums.garmin.com/developer/connect-iq/i/bug-reports/stackoverflowerror-during-build-for-tuple-with-self-reference
typedef SerializedBreadCrumb as [Number, Array<SerializedBreadCrumb> or Null ];