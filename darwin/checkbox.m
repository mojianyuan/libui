// 14 august 2015
#import "uipriv_darwin.h"

// TODO the intrinsic height of this seems to be wacky

struct uiCheckbox {
	uiDarwinControl c;
	NSButton *button;
	void (*onToggled)(uiCheckbox *, void *);
	void *onToggledData;
};

@interface checkboxDelegateClass : NSObject {
	struct mapTable *buttons;
}
- (IBAction)onToggled:(id)sender;
- (void)registerCheckbox:(uiCheckbox *)c;
- (void)unregisterCheckbox:(uiCheckbox *)c;
@end

@implementation checkboxDelegateClass

- (id)init
{
	self = [super init];
	if (self)
		self->buttons = newMap();
	return self;
}

- (void)dealloc
{
	mapDestroy(self->buttons);
	[super dealloc];
}

- (IBAction)onToggled:(id)sender
{
	uiCheckbox *c;

	c = (uiCheckbox *) mapGet(self->buttons, sender);
	(*(c->onToggled))(c, c->onToggledData);
}

- (void)registerCheckbox:(uiCheckbox *)c
{
	mapSet(self->buttons, c->button, c);
	[c->button setTarget:self];
	[c->button setAction:@selector(onToggled:)];
}

- (void)unregisterCheckbox:(uiCheckbox *)c
{
	[c->button setTarget:nil];
	mapDelete(self->buttons, c->button);
}

@end

static checkboxDelegateClass *checkboxDelegate = nil;

uiDarwinDefineControlWithOnDestroy(
	uiCheckbox,								// type name
	button,									// handle
	[checkboxDelegate unregisterCheckbox:this];		// on destroy
)

char *uiCheckboxText(uiCheckbox *c)
{
	return uiDarwinNSStringToText([c->button title]);
}

void uiCheckboxSetText(uiCheckbox *c, const char *text)
{
	[c->button setTitle:toNSString(text)];
	// this may result in the size of the checkbox changing
	// TODO something somewhere is causing this to corrupt some memory so that, for instance, page7b's mouseExited: never triggers on 10.11; figure out what
	// TODO is this related to map-related crashes?
	uiDarwinControlTriggerRelayout(uiDarwinControl(c));
}

void uiCheckboxOnToggled(uiCheckbox *c, void (*f)(uiCheckbox *, void *), void *data)
{
	c->onToggled = f;
	c->onToggledData = data;
}

int uiCheckboxChecked(uiCheckbox *c)
{
	return [c->button state] == NSOnState;
}

void uiCheckboxSetChecked(uiCheckbox *c, int checked)
{
	NSInteger state;

	state = NSOnState;
	if (!checked)
		state = NSOffState;
	[c->button setState:state];
}

static void defaultOnToggled(uiCheckbox *c, void *data)
{
	// do nothing
}

uiCheckbox *uiNewCheckbox(const char *text)
{
	uiCheckbox *c;

	c = (uiCheckbox *) uiNewControl(uiCheckbox);

	c->button = [[NSButton alloc] initWithFrame:NSZeroRect];
	[c->button setTitle:toNSString(text)];
	[c->button setButtonType:NSSwitchButton];
	[c->button setBordered:NO];
	uiDarwinSetControlFont(c->button, NSRegularControlSize);

	if (checkboxDelegate == nil) {
		checkboxDelegate = [checkboxDelegateClass new];
		[delegates addObject:checkboxDelegate];
	}
	[checkboxDelegate registerCheckbox:c];
	uiCheckboxOnToggled(c, defaultOnToggled, NULL);

	uiDarwinFinishNewControl(c, uiCheckbox);

	return c;
}
