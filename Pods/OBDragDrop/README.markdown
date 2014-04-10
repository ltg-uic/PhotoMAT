OBDragDrop
=============

OBDragDrop is a compact iOS UI library for drag and drop. It is self-contained and depends only on UIKit.

Features:

* Drag and drop between any UIViews
* Any view can be draggable, and any view can be a drop target
* Visuals exists on a UIWindow that sits on top of the app
* Various events for different stages of a drag and drop gesture



Installation
============
Simply drag the files into your project and go! No need to mess with library paths, target dependencies, etc



Implementation
==============

Dragging is initiated when a custom UIGestureRecognizer is attached to a source view, typically this is a UILongPressGestureRecognizer but other recognizer types could be made to work in the future. This recognizer should be created from OBDragDropManager which serves as a factory object

The view that is dragged then asks its OBOvumSource, typically the UIViewController, for information on the data object that should be attached to the drag and drop.

The OBOvum object encapsulates the drag and drop gesture, calling delegate methods on the drop zone for events such as enter, move, drop, and exit.

For each view that an OBOvum can be dropped in simply attach a drop zone handler, typically also the UIViewController, and implementing the necessary delegate methods.



Code Snippets
=============

#### Set Up

The one set up call necessary to initialize the drag drop manager is to associate it with the main window. Typically call this when the application loads inside your app delegate or context

```
	OBDragDropManager *manager = [OBDragDropManager sharedManager];
	[manager prepareOverlayWindowUsingMainWindow:self.window];
```


#### Instantiating a OBDragDropRecognizer

Use OBDragDropManager as a factory for the drag drop specific gesture 
recognizers and attach it to your view. You can now use any gesture recognizer of your choosing, but it should be a continuous tracking gesture rather than discrete actions.

```
	OBDragDropManager *dragDropManager = [OBDragDropManager sharedManager];

	// Drag and drop using long press
	UILongPressGestureRecognizer *dragDropRecognizer = [dragDropManager createLongPressDragDropGestureRecognizerWithSource:self];
	[view addGestureRecognizer:dragDropRecognizer];

	// Drag and drop using pan
	UIGestureRecognizer *panRecognizer = [dragDropManager createDragDropGestureRecognizerWithClass:[UIPanGestureRecognizer class] source:self];
	[view addGestureRecognizer:panRecognizer];
```


#### Using OBDragDropManager

<pre>
-(OBOvum *) createOvumFromView:(UIView*)sourceView
{
	OBOvum *ovum = [[[OBOvum alloc] init] autorelease];
	ovum.dataObject = [sourceView model];
	return ovum;
}


-(UIView *) createDragRepresentationOfSourceView:(UIView *)sourceView inWindow:(UIWindow*)window
{
	// Create a view that represents this source. It will be place on
	// the overlay window and hence the coordinates conversion to make
	// sure user doesn't see a jump in object location
	CGRect frameInWindow = [assetView convertRect:sourceView.frame toView:sourceView.window];
	frameInWindow = [window convertRect:frameInWindow fromWindow:sourceView.window];

	UIImageView *dragImage = [[[UIImageView alloc] initWithFrame:frameInWindow] autorelease];
	dragImage.image = [(UIImageView*) sourceView image];
	dragImage.contentMode = UIViewContentModeScaleAspectFit;
	return dragImage;
}

</pre>


#### Drop Zone handling
<pre>
-(void) viewDidLoad
{
	[super viewDidLoad];

	// Register view as a drop zone that will be handled by its controller
	self.view.dropZoneHandler = self;
}

-(OBDropAction) ovumEntered:(OBOvum*)ovum inView:(UIView*)view atLocation:(CGPoint)location
{  
	self.view.backgroundColor = [UIColor redColor];
	return OBDropActionCopy;	// Return OBDropActionNone if view is not currently accepting this ovum
}

-(void) ovumExited:(OBOvum*)ovum inView:(UIView*)view atLocation:(CGPoint)location
{
	self.view.backgroundColor = [UIColor clearColor];
}


-(void) ovumDropped:(OBOvum*)ovum inView:(UIView*)view atLocation:(CGPoint)location
{
	// Handle the drop action
}
</pre>



Example
=======
There's a simple example project called OBDragDropTest which demonstrates the basic functionality of the library.



License
=======
This library is released under an MIT license.

