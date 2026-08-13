#import <UIKit/UIKit.h>

#define ALERT_TITLE @"التراث ستور"
#define ALERT_MESSAGE @"للحصول على كود التفعيل الرجاء الانضمام إلى قناتنا"
#define BUTTON_ACTION_TITLE @"اضغط هنا"
#define BUTTON_CLOSE_TITLE @"إغلاق"
#define TARGET_URL_STRING @"https://t.me/turath_st/743"

static BOOL gAlertAlreadyShown = NO;

static UIWindow *TAGetActiveWindow(void) {
    UIApplication *application = UIApplication.sharedApplication;

    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in application.connectedScenes) {
            if (![scene isKindOfClass:[UIWindowScene class]]) {
                continue;
            }

            UIWindowScene *windowScene = (UIWindowScene *)scene;

            if (scene.activationState == UISceneActivationStateUnattached) {
                continue;
            }

            for (UIWindow *window in windowScene.windows) {
                if (window.isKeyWindow) {
                    return window;
                }
            }

            UIWindow *visibleWindow = windowScene.windows.lastObject;
            if (visibleWindow != nil) {
                return visibleWindow;
            }
        }
    }

    for (UIWindow *window in application.windows) {
        if (window.isKeyWindow) {
            return window;
        }
    }

    return application.windows.lastObject;
}

static UIViewController *TAFindTopViewController(UIViewController *viewController) {
    if (viewController == nil) {
        return nil;
    }

    if (viewController.presentedViewController != nil) {
        return TAFindTopViewController(viewController.presentedViewController);
    }

    if ([viewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController =
            (UINavigationController *)viewController;

        return TAFindTopViewController(navigationController.visibleViewController);
    }

    if ([viewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tabBarController =
            (UITabBarController *)viewController;

        return TAFindTopViewController(tabBarController.selectedViewController);
    }

    if ([viewController isKindOfClass:[UISplitViewController class]]) {
        UISplitViewController *splitViewController =
            (UISplitViewController *)viewController;

        return TAFindTopViewController(splitViewController.viewControllers.lastObject);
    }

    for (UIViewController *child in viewController.children.reverseObjectEnumerator) {
        if (child.viewIfLoaded.window != nil) {
            return TAFindTopViewController(child);
        }
    }

    return viewController;
}

static BOOL TATryPresentAlert(void) {
    if (gAlertAlreadyShown) {
        return YES;
    }

    UIWindow *window = TAGetActiveWindow();

    if (window == nil || window.rootViewController == nil) {
        return NO;
    }

    UIViewController *presenter =
        TAFindTopViewController(window.rootViewController);

    if (presenter == nil || presenter.viewIfLoaded.window == nil) {
        return NO;
    }

    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:ALERT_TITLE
                                            message:ALERT_MESSAGE
                                     preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *openAction =
        [UIAlertAction actionWithTitle:BUTTON_ACTION_TITLE
                                 style:UIAlertActionStyleDefault
                               handler:^(__unused UIAlertAction *action) {
        NSURL *url = [NSURL URLWithString:TARGET_URL_STRING];

        if (url == nil) {
            return;
        }

        [[UIApplication sharedApplication]
            openURL:url
            options:@{}
            completionHandler:nil];
    }];

    UIAlertAction *closeAction =
        [UIAlertAction actionWithTitle:BUTTON_CLOSE_TITLE
                                 style:UIAlertActionStyleCancel
                               handler:nil];

    [alert addAction:openAction];
    [alert addAction:closeAction];

    gAlertAlreadyShown = YES;

    [presenter presentViewController:alert
                             animated:YES
                           completion:nil];

    return YES;
}

static void TAScheduleAlertAttempt(NSInteger retries) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (TATryPresentAlert()) {
            return;
        }

        if (retries <= 0) {
            return;
        }

        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                (int64_t)(700 * NSEC_PER_MSEC)
            ),
            dispatch_get_main_queue(),
            ^{
                TAScheduleAlertAttempt(retries - 1);
            }
        );
    });
}

%ctor {
    @autoreleasepool {
        [[NSNotificationCenter defaultCenter]
            addObserverForName:UIApplicationDidFinishLaunchingNotification
                        object:nil
                         queue:[NSOperationQueue mainQueue]
                    usingBlock:^(__unused NSNotification *notification) {
            TAScheduleAlertAttempt(6);
        }];

        // للتعامل مع الحقن المتأخر بعد اكتمال تشغيل التطبيق
        TAScheduleAlertAttempt(4);
    }
}
