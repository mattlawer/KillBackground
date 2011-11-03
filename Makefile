SDKVERSION = 5.0
IPHONEOS_DEPLOYMENT_TARGET = 4.0

include theos/makefiles/common.mk

SUBPROJECTS = killbackgroundpreferences
TWEAK_NAME = KillBackground
KillBackground_FILES = Tweak.xm
KillBackground_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk
