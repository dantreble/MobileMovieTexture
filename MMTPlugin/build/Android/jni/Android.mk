#$(info makefiles beeing called: $(call all-subdir-makefiles))
#include $(call all-subdir-makefiles)

include ../../../ogg/Android.mk
include ../../../oggz/Android.mk
include ../../../theorawrapper/Android.mk
include ../../../theora/Android.mk