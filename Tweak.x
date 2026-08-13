#import <UIKit/UIKit.h>

#define ALERT_TITLE @"التراث ستور"
#define ALERT_MESSAGE @"للحصول على كود التفعيل الرجاء الانضمام إلى قناتنا"
#define BUTTON_ACTION_TITLE @"اضغط هنا"
#define BUTTON_CLOSE_TITLE @"إغلاق"
#define TARGET_URL_STRING @"https://t.me/turath_st/744"

static BOOL gAlertAlreadyShown = NO;

static BOOL TAIsUsableWindow(UIWindow *window) {
    return window != nil &&
           !window.hidden &&
           window.alpha > 0.0 &&
           window.rootViewController != nil;
}

static UIWindow *TAGetActiveWindow(void) {
    UIApplication *application = UIApplication.sharedApplication;

    if (@available(iOS 13.0, *)) {
        // ابحث أولًا في المشاهد النشطة حتى لا نحاول عرض التنبيه فوق تطبيق
        // موجود في الخلفية أو فوق مشهد غير مستخدم.
        for (UIScene *scene in application.connectedScenes) {
            if (![scene isKindOfClass:[UIWindowScene class]]) {
                continue;
            }

            UIWindowScene *windowScene = (UIWindowScene *)scene;

            if (scene.activationState != UISceneActivationStateForegroundActive) {
                continue;
            }

            for (UIWindow *window in windowScene.windows) {
                if (window.isKeyWindow && TAIsUsableWindow(window)) {
                    return window;
                }
            }

            for (UIWindow *window in windowScene.windows) {
                if (TAIsUsableWindow(window)) {
                    return window;
                }
            }
        }

        // إذا لم توجد نافذة نشطة لحظة المحاولة، استخدم مشهدًا في الواجهة
        // لكنه غير نشط مؤقتًا، وسيعيد المجدول المحاولة لاحقًا.
        for (UIScene *scene in application.connectedScenes) {
            if (![scene isKindOfClass:[UIWindowScene class]] ||
                scene.activationState != UISceneActivationStateForegroundInactive) {
                continue;
            }

            UIWindowScene *windowScene = (UIWindowScene *)scene;

            for (UIWindow *window in windowScene.windows) {
                if (window.isKeyWindow && TAIsUsableWindow(window)) {
                    return window;
                }
            }

            for (UIWindow *window in windowScene.windows) {
                if (TAIsUsableWindow(window)) {
                    return window;
                }
            }
        }

        return nil;
    }

    // دعم الأجهزة التي تعمل بإصدارات iOS أقدم من 13.
    for (UIWindow *window in application.windows) {
        if (window.isKeyWindow && TAIsUsableWindow(window)) {
            return window;
        }
    }

    for (UIWindow *window in application.windows) {
        if (TAIsUsableWindow(window)) {
            return window;
        }
    }

    return nil;
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

        return TAFindTopViewController(
            navigationController.visibleViewController
        );
    }

    if ([viewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tabBarController =
            (UITabBarController *)viewController;

        return TAFindTopViewController(
            tabBarController.selectedViewController
        );
    }

    if ([viewController isKindOfClass:[UISplitViewController class]]) {
        UISplitViewController *splitViewController =
            (UISplitViewController *)viewController;

        return TAFindTopViewController(
            splitViewController.viewControllers.lastObject
        );
    }

    // الاسم الصحيح في Objective-C هو childViewControllers
    // وليس children.
    for (UIViewController *child in
         [viewController.childViewControllers reverseObjectEnumerator]) {
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

        // للتعامل مع الحقن المتأخر بعد اكتمال تشغيل التطبيق.
        TAScheduleAlertAttempt(4);
    }
}
